require 'ladon'

module Users
  # Encapsulates the algorithm for choosing a set of listings that represent a user's tastes and personality.
  # Subclasses implement the +#find_candidate_listings+ method to provide different sets of candidate listings,
  # which are then filtered by this class to remove non-visible listings and indexed in a variety of ways.
  class RepresentativeListingsPolicy
    include Ladon::Logging

    DEFAULT_LISTING_COUNT = 4

    # the number of listings to choose
    attr_reader :listing_count

    # the chosen listings
    attr_reader :listings

    def initialize(options = {})
      @listing_count = options.fetch(:count, DEFAULT_LISTING_COUNT)
      @listings = []
      @listings_by_id = {}
      @listing_ids_by_user = {}
      @photos_by_listing_id = {}
    end

    # Chooses up to +#listing_count+ representative listings for each user. The initial set of candidate ids is provided
    # by +#find_candidate_listing_ids+. The visible listings from that set and their primary photos are fetched and
    # indexed.
    def choose!(users)
      candidate_listing_ids_by_user_id = find_candidate_listing_ids(users)
      all_ids = candidate_listing_ids_by_user_id.values.flatten(1).uniq
      if all_ids.any?
        @listings = Listing.visible(all_ids).all
        if @listings.any?
          @listings_by_id = @listings.each_with_object({}) { |l, m| m[l.id] = l }
          @listing_ids_by_user = candidate_listing_ids_by_user_id.each_with_object({}) do |(user_id, listing_ids), m|
            m[user_id] = listing_ids.select {|id| @listings_by_id.key?(id)}
          end
          @photos_by_listing_id = ListingPhoto.find_primaries(@listings.map(&:id))
        end
      end
    end

    # Returns up to +#listing_count+ candidate listing ids for each user. Must be implemented by subclasses.
    #
    # @return [Hash] candidate listing ids mapped by user id
    def find_candidate_listing_ids(users)
      raise UnimplementedError
    end

    def listing(id)
      @listings_by_id[id]
    end

    def photo_for_listing(id)
      @photos_by_listing_id[id]
    end

    def listings_for_user(user_id)
      @listing_ids_by_user.fetch(user_id, []).map { |id| @listings_by_id[id] }
    end

    def photos_for_user(user_id)
      @listing_ids_by_user.fetch(user_id, []).map { |id| @photos_by_listing_id[id] }
    end
  end
end
