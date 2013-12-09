require 'faraday'
require 'faraday_middleware'
require 'nokogiri'
require 'securerandom'
require 'uri'

class ListingSource < ActiveRecord::Base
  has_many :images, class_name: 'ListingSourceImage', dependent: :destroy
  attr_accessible :url, :title, :price
  validate :must_have_an_image

  # See RFC 2396 for more on valid URI characters.
  INVALID_URIC_REGEX = Regexp.new("[^%##{URI::PATTERN::RESERVED}#{URI::PATTERN::UNRESERVED}]")

  def relevant_images(options = {})
    # algorithm for determining relevance:
    #
    # 1. for those images which we were able to determine dimensions, filter out the ones that are too small and
    #    then order largest to smallest.
    # 2. then, for those images for which we were able to determine file size, filter out the ones that are too small
    #    and then order largest to smallest.
    # 3. prioritize all images with dimensions over those with file sizes only. this generally results in the best
    #    image showing up as most relevant; out of ~30 tests, only a handful had the best image showing up in any
    #    slot other than first.

    (images_with_area, images_without_area) = images.partition { |i| i.area.present? }

    relevant = images_with_area.
      find_all { |i| i.area >= self.class.config.image_minimum_area }.
      sort { |a, b| b.area <=> a.area }

    relevant += images_without_area.
      find_all { |i| i.size.present? && i.size >= self.class.config.image_minimum_size }.
      sort { |a, b| b.size <=> a.size }

    options[:count] ? relevant.take(options[:count]) : relevant
  end

  def domain
    unless instance_variable_defined?(:@domain)
      return nil if uri.nil?
      @domain = uri.host.split('.').reverse.take(2).reverse.join('.')
    end
    @domain
  end

  def uri
    unless instance_variable_defined?(:@uri)
      return nil if url.blank?
      @uri = URI(url)
    end
    @uri
  end

  before_create do
    self.uuid = SecureRandom.uuid
  end

  def to_param
    uuid
  end

  protected
    def must_have_an_image
      (images_with_area, images_without_area) = images.partition { |i| i.area.present? }
      has_image_of_sufficient_area = images_with_area.any? do |i|
        i.area >= self.class.config.image_minimum_area
      end
      unless has_image_of_sufficient_area
        has_image_of_sufficient_size = images_without_area.any? do |i|
          i.size.present? && i.size >= self.class.config.image_minimum_size
        end
        unless has_image_of_sufficient_size
          errors.add(:images, I18n.t('activerecord.errors.models.listing_source.attributes.images.empty'))
        end
      end
    end

  # @raise Faraday::Error::ClientError
  def self.scrape(url)
    scraper = Scraper.new(url)
    source = new(url: scraper.url, title: scraper.title, price: scraper.price)
    images = scraper.images
    images.unshift(scraper.open_graph_image) if scraper.open_graph_image
    images.each do |image|
      begin
        url = image.url
      rescue URI::InvalidComponentError => e
        logger.debug("Could not build image: #{e.message}")
        next
      end
      attrs = {
        url: url,
        height: image.height,
        width: image.width
      }
      # getting the size forces a network connection to the image host, so only do it if we really need it
      attrs[:size] = image.size unless image.has_dimensions?
      source.images.build(attrs)
    end
    source
  end

  # Construct a new listing source from parameters passed in from the bookmarklet.
  # @param [Hash] options parameters passed to brooklyn from the bookmarklet
  # @options options [String] :url original url for the external page
  # @options options [String] :title title of the external page
  # @options options [String] :price parsed price from the external page (w/o currency marker)
  # @options options [Hash] :images hash containing at least one image parsed by the bookmarklet.  Each image
  #   specifies a width and height
  def self.build_from_bookmarklet(options = {})
    escaped_url = escape_source_url(options[:url])
    source = new(url: escaped_url, title: options[:title], price: options[:price])
    images = HashWithIndifferentAccess.new(options.fetch(:images, nil))
    images.each do |url, h|
      data = {url: url}
      data.reverse_merge!(height: h[:height], width: h[:width]) if h.is_a?(Hash)
      source.images.build(data)
    end
    source
  end

  def self.escape_source_url(url = '')
    URI.escape(url, INVALID_URIC_REGEX)
  end

  def self.config
    Brooklyn::Application.config.listing_sources
  end

  # included in ListingSource so that I can autoload changes in dev; putting it in lib would mean I'd have to restart
  # the damn server for every change.
  class Scraper
    include ActiveSupport::Benchmarkable

    class UnacceptableMediaType < Faraday::Error::ClientError; end

    HTTP_URL = Regexp.new('^https?')
    SLASHES_URL = Regexp.new('^//')
    PRICE = Regexp.new('\$([\d\s\.]{1,256})')
    ACCEPTABLE_MEDIA_TYPE = Regexp.new('text/html')

    attr_reader :uri

    # @raise URI::InvalidURIError if +url+ can't be parsed
    def initialize(url)
      if url !~ HTTP_URL
        if url =~ SLASHES_URL
          url = "http:#{url}"
        else
          url = "http://#{url}"
        end
      end
      url = URI.escape(url, INVALID_URIC_REGEX)
      @uri = URI(url)
    end

    def url
      uri.to_s
    end

    def title
      @title ||= document.title
    end

    def open_graph_image
      # XXX: support structured properties listed at http://ogp.me/
      unless instance_variable_defined?(:@open_graph_image)
        nodes = document.css('meta[property="og:image"]')
        @open_graph_image = Img.new(nodes.first, uri, fetcher) if nodes.any?
      end
      @open_graph_image
    end

    def images
      unless instance_variable_defined?(:@images)
        @images = document.css('img').map do |node|
          # even though we omit small images when presenting them to the user for selection, we still want to retain
          # knowledge of them locally so that we are free to change our rules about which ones to present without
          # having to rescrape later.
          # on the other hand, we never care about images served from known ad domains, so XXX: filter those out
          Img.new(node, uri, fetcher)
        end
      end
      @images
    end

    def price
      unless instance_variable_defined?(:@price)
        # look for a node with text content of the general form "$xx.yy". there may be whitespace between the currency
        # symbol and digits.
        #
        # because we want to ignore script content, clone the document and remove those elements from the clone.
        clone = document.clone
        clone.css('script').remove
        # strip whitespace from the match string so that something like "1.       25. " converts to 1.25 correctly.
        @price = $1.gsub(/\s/, '').to_d if clone.text =~ PRICE
      end
      @price
    end

    def document
      @document ||= benchmark("Parse #{uri} for scraping") do
        Nokogiri::HTML(content)
      end
    end

    # @raise [Faraday::Error::ClientError]
    def content
      unless instance_variable_defined?(:@content)
        response = fetcher.fetch(uri)
        media_type = response.headers['Content-Type']
        unless media_type.present? && media_type =~ ACCEPTABLE_MEDIA_TYPE
          raise UnacceptableMediaType.new("Unacceptable media type: #{media_type}")
        end
        @content = response.body
      end
      @content
    end

    def fetcher
      @fetcher ||= Fetcher.new
    end

    def logger
      self.class.logger
    end

    def self.config
      Brooklyn::Application.config.listing_sources.scraper
    end

    def self.logger
      ListingSource.logger
    end

    class Img
      attr_reader :node, :base_uri, :fetcher

      def initialize(node, base_uri, fetcher)
        @node = node
        @base_uri = base_uri
        @fetcher = fetcher
      end

      def url
        uri.to_s
      end

      HTTP_URL = Regexp.new('^https?')
      FILE_URL = Regexp.new('^file://')
      SLASHES_URL = Regexp.new('^//')
      ROOT_RELATIVE_URL = Regexp.new('^/')

      def uri
        unless instance_variable_defined?(:@uri)
          src = node['src'] || node['content']
          src = URI.escape(src, INVALID_URIC_REGEX)
          (path, query) = src.present? ? src.split('?') : [src, nil]
          @uri = if src =~ HTTP_URL
            URI(src)
          elsif src =~ FILE_URL
            # useful for referencing local images in tests
            URI(src)
          elsif src =~ SLASHES_URL
            URI("#{base_uri.scheme}:#{src}")
          elsif src=~ ROOT_RELATIVE_URL
            uri = base_uri.dup
            uri.path = path
            uri.query = query if query.present?
            uri
          else              # relative to base url
            # XXX: doesn't take ../ or ./ into account. so many more cases to consider.
            uri = base_uri.dup
            base_path = if base_uri.path.present?
              if base_uri.path.ends_with?('/')
                # relative to base path
                base_uri.path
              else
                # relative to to final parent segment of base path
                segments = base_uri.path.split('/')
                "#{segments.take(segments.length-1).join('/')}/"
              end
            else
              # relative to root
              '/'
            end
            uri.path = "#{base_path}#{path}"
            uri.query = query if query.present?
            uri
          end
        end
        @uri
      end

      def height
        unless instance_variable_defined?(:@height)
          (@height, @width) = determine_dimensions
        end
        @height
      end

      def width
        unless instance_variable_defined?(:@width)
          (@height, @width) = determine_dimensions
        end
        @width
      end

      CSS_DIMENSION_PROPERTY = Regexp.new('(height|width)')
      CSS_DIMENSION_VALUE = Regexp.new('^(\d+)px$')
      CSS_RULE_SEPARATOR = Regexp.new('\s*;\s*')

      def determine_dimensions
        if node['height'].present? || node['width'].present?
          # parse height and width out of the dimension attributes
          %w(height width).map do |k|
            (node[k].present? ? node[k].to_i : nil)
          end
        elsif node['style'] =~ CSS_DIMENSION_PROPERTY
          # parse height and width out of the inline style
          rules = node['style'].split(CSS_RULE_SEPARATOR).each_with_object({}) do |rule, m|
            (k, v) = rule.split(':')
            m[k] = v
          end
          %w(height width).map do |k|
            v = rules[k]
            if v.present? && v =~ CSS_DIMENSION_VALUE # ignore any value that isn't specified in pixels
              $1.to_i
            else
              nil
            end
          end
        else
          # couldn't find any useful info
          [nil, nil]
        end
      end

      def size
        unless instance_variable_defined?(:@size)
          response = begin
            fetcher.fetch(uri, method: :head)
          rescue Exception => e
            # log at debug level so we can find it later but it doesn't show up on the warning radar. usually this is
            # a 403 forbidden or 405 method not allowed (ebay, jeez) or occasionally a server error.
            logger.debug("Couldn't fetch image #{uri} to find its size: #{e}")
            nil
          end
          if response && response.headers && response.headers.key?('Content-Length')
            @size = response.headers['Content-Length'].to_i
          end
        end
        @size
      end

      def has_dimensions?
        height.present? || width.present?
      end

      def logger
        self.class.logger
      end

      def self.config
        ListingSource::Scraper.config
      end

      def self.logger
        ListingSource::Scraper.logger
      end
    end

    class Fetcher
      include ActiveSupport::Benchmarkable

      # Connect to +uri+ and return the response for further processing.
      #
      # @option :method
      # @raise [Faraday::Error::ClientError] when the response status is in the 400 or 500 range
      def fetch(uri, options = {})
        conn = Faraday::Connection.new do |c|
          # must be first in the stack
          c.response :raise_error
          c.response :follow_redirects, cookies: :all
          # the version of typheous we're using overrides the user agent header
          # must be last in the stack
          c.adapter :net_http
        end
        method = options.fetch(:method, :get).to_sym
        response = benchmark("#{method.to_s.upcase} #{uri}") do
          conn.send(method) do |req|
            req.url(uri)
            req.headers[:user_agent] = self.class.config.user_agent
            req.options[:timeout] = self.class.config.read_timeout
            req.options[:open_timeout] = self.class.config.open_timeout
          end
        end
        response
      end

      def logger
        self.class.logger
      end

      def self.config
        ListingSource::Scraper.config
      end

      def self.logger
        ListingSource::Scraper.logger
      end
    end
  end
end
