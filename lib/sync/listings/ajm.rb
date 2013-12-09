require 'brooklyn/carrierwave'
require 'csv'
require 'sync/listings'

module Sync
  module Listings
    # AJM Fashions was originally a customer of Kyozou, who provided the actual listing management system.
    # They subsequently switched to Channel Advisor, a different provider.  However, these sellers seem a bit fickle
    # so we're keeping the Kyozou configuration around for now.
    #
    # Both providers push datafeeds to S3 via FTP on a periodic basis.
    #
    # XXX: The categories used by Kyozou are ebay category ids.  Those used by Channel Advisor are descriptive text.
    # In both cases, we only have the ones that we know about.  Channel Advisor will be sending a list of all
    # categories.  Depending on how big that is, we may need a different approach to management.
    class Ajm < Sync::Listings::Source

      class << self
        attr_reader :provider, :provider_class, :adapter_class
        attr_accessor :max_tag_length

        def provider=(provider)
          prefix = provider.to_s.classify
          @provider_class = Sync::Listings.const_get("#{prefix}Provider".to_sym)
          @adapter_class = const_get("#{prefix}Adapter".to_sym)
          @provider = provider
        end

        def bucket=(bucket)
          @provider_class.bucket = bucket
        end

        def pattern=(pattern)
          @provider_class.pattern = pattern
        end
      end

      def each(&block)
        self.class.provider_class.new.each { |o| block.call(self.class.adapter_class.new(o)) }
      end

      class Adapter < Sync::Listings::Adapter
        include ActionView::Helpers::NumberHelper

        attr_reader :row

        # create an instance using a hash of a row in the import CSV file
        def initialize(row)
          @row = row
          @pricing_version = Sync::Listings::Ajm.pricing_version
        end

        def title
          @title ||= row['Title']
        end

        def original_title
          title
        end

        def tag_names
          @tag_names ||= details.map { |d| row[d] }.select do |n|
            n.present? && n.length < Sync::Listings::Ajm.max_tag_length.to_i
          end.uniq
        end

        def tag_names_no_create
          # if any word or string of consecutive words (up to 5 long) from the title matches a tag,
          # we want to add that as a tag on a the listing
          # every title now ends with "$YY.YY New" and "New" on its own here would be misleading
          title_words = original_title.split.reject { |w| w == 'New' }
          tag_candidates = title_words.dup
          (2..5).each { |i| title_words.each_cons(i) { |s| tag_candidates << s.join(' ') } }
          tag_candidates
        end

        def description
          description = ["<ul>"]
          description << "<li><b>Retail Price</b>: #{number_to_currency(msrp)}</li>"
          details.each do |key|
            value = row[key]
            description << "<li><b>#{key.titlecase}:</b> #{value}</li>" if value && value.length > 0
          end
          description << "</ul>"
          description << original_description
          description.join
        end

        def photo_files
          photo_urls.map do |url|
            Regexp.new("http://.*/(?<prefix>[0-9a-z%\._-]+).jpg").match(url) do |m|
              ImageFile.new(url, m[:prefix])
            end
          end
        end
      end

      class KyozouAdapter < Adapter
        DETAILS = ['style', 'color', 'size', 'material']
        NO_50_PERCENT = ['shoes', 'handbags']
        UNSPECIFIED_CONDITION  = ['shoes']

        def uid
          @uid ||= row['ID']
        end

        def msrp
          # kyozou put the price in the wrong column, so MSRP is actually under 'Buy It Now' (BIN).  However, AJM's
          # price is always 50% of retail, so we map it here and show the original retail price in the description
          row['KZBIN'].to_f
        end

        def original_description
          row['description']
        end

        def price
          msrp / 2
        end

        def shipping
          row['shipping price'].to_f
        end

        def photo_urls
          # the kyozou feed has the primary photo reliably in the last spot, while the rest are in the correct order
          # the total number of photos for a listing varies, but there cannot be more than 10
          urls = (1..10).map { |i| row["image link #{i}"] }.select { |u| u && u.length > 0 }
          urls.insert(0, urls.pop)
        end

        def category_slug
          @category_slug ||= Sync::Listings::Ajm.categories[row['product_type'].to_s.to_sym].to_s
        end

        def title
          # totally AJM specific detail
          @title ||= NO_50_PERCENT.include?(category_slug) ? original_title : original_title + ' - 50% Off Retail'
        end

        def original_title
          row['Title']
        end

        def condition
          # hard to memoize nil, but not the most expensive operation...
          'New' unless UNSPECIFIED_CONDITION.include?(@category_slug)
        end

        def details
          DETAILS
        end
      end

      class ChannelAdvisorAdapter < Adapter
        DETAILS = ['Style', 'Color', 'Size', 'Material']

        def uid
          row['SKU']
        end

        def original_description
          @original_description ||= begin
            # XXX: workaround for a channel advisor bug where multiple lines of description are mashed together
            # without a space, creating camel-case text that identifies what should be a line break
            # Since a second manifestation puts 2 spaces in between the lines, we sub those in and then split on
            # two spaces so we can handle both.
            # XXX: all this crap should be removed when they actually fix their feed, but that's weeks away
            # apparently
            lines = row['Description'].gsub(/(?<=[a-z])([A-Z])/, "  \\1").split('  ')
            "<ul><li>#{lines.join('</li><li>')}</li></ul>"
          end
        end

        def price
          row['Price']
        end

        def shipping
          row['ShippingPrice']
        end

        def msrp
          row['MSRP']
        end

        def category_slug
          @category_slug ||= Sync::Listings::Ajm.categories[row['Category'].to_sym].to_s
        end

        def condition
          # seems to be some junk in this feed, so we'll use a default instead of trying
          # to understand it
          row['Condition'] == 'NEW' ? 'New' : 'Used'
        end

        def photo_urls
          (1..9).map { |i| row["ProductImage#{i}"] }.select { |u| u && u.length > 0 }
        end

        def details
          DETAILS
        end
      end

      class ImageFile < Brooklyn::CarrierWave::RemoteImageFile
        def initialize(url, file_prefix)
          super(url)
          @uid = file_prefix
        end
      end
    end
  end
end
