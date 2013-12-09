require 'active_support/concern'
require 'brooklyn/sprayer'

module Listings
  module Api
    extend ActiveSupport::Concern
    include Brooklyn::Sprayer
    include Brooklyn::Urls

    #returns true if listing is by an api user
    def api?
      seller.api_config.present?
    end

    #returns hash for api listing, by default the full details.
    def api_hash(options = {})
      hash = {
        slug: slug,
        source_uid: source_uid,
        link: [{ href: self.class.url_helpers.api_listing_url(self) }, { rel: 'alternate', href: self.class.url_helpers.listing_url(self) }]
      }
      hash.merge!(basic_options) unless options[:summary]
      hash.merge!(extra_options) if options[:extra]
      hash
    end

    private

    def basic_options
      hash = {
        title: title,
        description: description,
        condition: condition,
        tags: tag_names,
        price: price.to_f,
        shipping: shipping.to_d
      }
      hash[:category] = category.slug if category
      hash
    end

    def extra_options
      hash = {
        created_at: created_at.to_i,
        seller_pays: seller_pays_marketplace_fee,
        free_shipping: free_shipping
      }
      hash[:brand] = brand.name if brand
      hash[:size] = size.name if size
      hash[:shipping_option_code] = shipping_option_code if shipping_option_code
      hash[:handling] = handling_duration if handling_duration
      hash[:photos] = photos.map do |p|
        {
          small: { link: absolute_url(p.version_url(:small)) },
          medium: { link: absolute_url(p.version_url(:medium)) },
          large: { link: absolute_url(p.version_url(:large)) }
        }
      end
      hash
    end
  end
end
