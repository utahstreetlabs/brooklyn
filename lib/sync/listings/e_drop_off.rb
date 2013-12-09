require 'brooklyn/carrierwave'
require 'csv'

module Sync
  module Listings
    class EDropOff < Sync::Listings::Source
      class << self
        attr_accessor :shipping
        @shipping = 9.00

        attr_accessor :url
        @url = 'http://shopedo.venturality.com/Product/CsvFeed'

        def each(&block)
          tmp = Tempfile.new('sync')
          response = Typhoeus::Request.get(@url)
          raise "Error fetching eDrop-Off CSV file (#{response.code})" unless response.code == 200
          response.body.force_encoding('UTF-8')
          tmp.write(response.body)
          tmp.rewind
          csv = CSV.new(tmp, headers: :first_row)
          csv.each do |row|
            adapter = Adapter.new(row)
            block.call(adapter)
          end
          tmp.close(true)
        end
      end

      class Adapter < Sync::Listings::Adapter
        # create an instance using a hash of a row in the import CSV file
        def initialize(row)
          @uid = row['Id']
          @title = row['name']
          @description = row['description']
          @price = row['price'].to_f
          @shipping = Sync::Listings::EDropOff.shipping
          @pricing_version = Sync::Listings::EDropOff.pricing_version
          @photo_urls = ([row['imgurl']] + row['secondary-images'].split(',').map { |u| u.strip }).uniq
          @category_names = row['categories'].split(',').map { |c| c.strip }
        end

        def photo_files
          @photo_urls.map do |url|
            # we need a unique id to create the local filenames
            # some photo urls seem to be busted (like a missing id in the middle) so we just ignore those
            Regexp.new("http://shopedo.venturality.com/Image/(?<filename>[^/]+)/300/400").match(url) do |m|
              ImageFile.new(url, m[:filename]) if m
            end
          end.compact
        end
      end

      # eDrop-Off's remote images are always jpg, but have no extension so we make that assumption here to
      # keep rmagick from exploding
      class ImageFile < Brooklyn::CarrierWave::RemoteImageFile
        def initialize(url, file_prefix)
          super(url, "#{file_prefix}.jpg")
          @uid = file_prefix
        end
      end
    end
  end
end
