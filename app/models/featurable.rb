module Featurable
  extend ActiveSupport::Concern

  module ClassMethods
    # @option [Boolean] order_by_position (true)
    def features_listings(options = {})
      opts = { class_name: 'ListingFeature', as: :featurable, dependent: :destroy }
      opts[:order] = 'position' if options.fetch(:order_by_position, true)
      has_many :features, opts
    end
  end

  module InstanceMethods
    def features_with_listings(options = {})
      scope = features.includes(:listing).order(:position)
      scope.limit(options[:limit]) if options[:limit]
      scope.all
    end

    def featured_listings(options = {})
      logger.debug("Loading featured listings")
      limit = options.fetch(:limit, 5)
      features.includes(listing: {seller: :person}).order(:position).limit(limit).map(&:listing)
    end

    def feature(listing)
      features << ListingFeature.new(listing: listing)
    end

    def unfeature(listing)
      f = features.where(listing_id: listing.id).first
      features.delete(f) if f
    end

    def find_feature(id)
      features.find(id)
    end

    def delete_feature(feature)
      features.delete(feature)
    end
  end
end
