require 'anchor/models/comment'

module Listings
  module Collections
    extend ActiveSupport::Concern

    included do
      has_many :listing_collection_attachments, dependent: :destroy
      has_many :collections, through: :listing_collection_attachments
      has_many :savers, source: 'user', through: :collections
      attr_accessor :add_to_collection_slugs
      attr_accessible :add_to_collection_slugs

      after_commit if: :persisted? do
        if add_to_collection_slugs
          self.update_collection_slugs_for(self.seller, add_to_collection_slugs)
        end
      end
    end

    def saves_count
      @saves_count ||= collections.count
    end

    def saved_by?(user)
      user.listing_saves.where(listing_id: self.id).exists?
    end

    def collections_owned_by(user)
      collections.where(user_id: user.id)
    end

    # Given a user and a set of collections, save this listing to any given collections
    # to which it is not yet saved and remove this listing from any collections to which
    # it is already saved that do not appear in the given set.
    def update_collections_for(user, collections, options = {})
      not_owned_collection = collections.find { |c| not c.owned_by?(user) }
      if not_owned_collection
        raise Exception.new("Tried to save listing to collection #{not_owned_collection.id}, which is not owned by user #{user.id}")
      end
      already_saved_collections = self.collections_owned_by(user)
      to_save_collections = collections - already_saved_collections
      to_remove_collections = already_saved_collections - collections
      self.class.transaction do
        self.collections += to_save_collections
        self.collections -= to_remove_collections
        @saves_count = nil
      end
    end

    def update_collection_slugs_for(user, collection_slugs, options = {})
      if collection_slugs && collection_slugs.any?
        self.update_collections_for(user, user.find_collections_by_slug(collection_slugs), options)
      end
    end

    module ClassMethods
      def saves_counts(listing_ids)
        ListingCollectionAttachment.listing_counts(listing_ids)
      end

      # Returns visible listings that have been liked by this user but not yet added to any of his collections.
      #
      # @option options [Array] :includes specifies associations to be eager fetched
      # @option options [Integer] :per the maximum number of listings to return
      def find_liked_not_already_in_owned_collections(user, options = {})
        subjoin = sprintf("%s lca JOIN %s c ON c.id = lca.collection_id AND c.user_id = %d",
                          ListingCollectionAttachment.quoted_table_name,
                          Collection.quoted_table_name,
                          user.id)
        # fetch at least 100 to try to get a good set of liked listings that aren't necessarily already in collections
        per = 100 if per.blank? || per < 100
        relation = Listing.liked_by(user, page: 1, per: per). # only considers visible listings
                           joins("LEFT JOIN (#{subjoin}) ON #{quoted_table_name}.id = lca.listing_id").
                           where('lca.id IS NULL')
        [:per, :includes].each do |meth|
          relation = relation.send(meth, options[meth]) if options[meth]
        end
        relation
      end

      # Returns visible listings that have been recently added to collections the user follows.
      #
      # @option options [Array] :excluded_ids specifies the ids of listings to exclude from the results
      # @option options [Array] :includes specifies associations to be eager fetched
      # @option options [Integer] :per the maximum number of listings to return
      def find_recently_created_from_followed_collections(user, options = {})
        # maybe use a join instead of a subquery? brane hurts
        relation = with_states(:active, :sold).
                   joins(:listing_collection_attachments).
                   where(listing_collection_attachments: {
                     collection_id: CollectionFollow.select(:collection_id).where(user_id: user.id)
                   }).
                   order("#{quoted_table_name}.created_at DESC").
                   page(1)
        if options[:excluded_ids]
          relation = relation.where("#{quoted_table_name}.id NOT IN (?)", Array.wrap(options[:excluded_ids]).join(','))
        end
        [:per, :includes].each do |meth|
          relation = relation.send(meth, options[meth]) if options[meth]
        end
        relation
      end

      # Returns listings that are good candidates for adding to the newly-created +collection+. Proposes listings
      # that have recently been created and added to the collections the user is following. If more suggestions are
      # required, proposes other listings that have been recently created without regard to collection membership.
      #
      # @option options [Object] :includes a list of includes to pass on to AR for eager fetching of listing
      #                                    associations
      # @option options [Integer] :count (20) the maximum number of listings to return
      # @return [Array] of suggested listings
      # @see +#find_recently_created_from_followed_collections+
      # @See +#find_recently_created+
      def find_recently_created_interesting(user, options = {})
        per = count = options[:count] || 20
        includes = options[:includes]
        excluded_ids = options[:excluded_ids]
        # to_a forces the query so that we don't get extraneous count queries on the relation later
        suggestions = user.recently_created_listings_from_followed_collections(includes: includes, per: per,
                                                                               excluded_ids: excluded_ids).to_a
        if suggestions.size < count
          per = count - suggestions.size
          excluded_ids = suggestions.map(&:id)
          suggestions += find_recently_created(includes: includes, per: per, excluded_ids: excluded_ids).to_a
        end
        suggestions
      end

      # Returns listings that are good candidates for adding to +collection+.
      #
      # @option options [Object] :includes a list of includes to pass on to AR for eager fetching of listing
      #                                    associations
      # @option options [Integer] :count (20) the maximum number of listings to return
      # @return [Array] of suggested listings
      # @see +#find_liked_not_already_in_owned_collections+
      # @see +#find_recently_created_interesting+
      def find_suggested_for_collection(collection, options = {})
        per = count = options[:count] || 20
        includes = options[:includes]
        # to_a forces the query so that we don't get extraneous count queries on the relation later
        suggestions =
          collection.user.liked_listings_not_already_in_owned_collections(includes: includes, per: per).to_a
        if suggestions.size < count
          per = count - suggestions.size
          excluded_ids = suggestions.map(&:id)
          suggestions += collection.user.recently_created_interesting_listings(includes: includes, count: per,
                                                                               excluded_ids: excluded_ids)
        end
        suggestions
      end

      # Returns a relation describing the listing saves (ListingCollectionAttachments) created by +user+ in reverse
      # chronological order.
      #
      # @options options [Integer] +:limit+
      # @options options [Array] +:exclude_sellers+ +User+s or ids whose listings should not be considered
      def recently_saved_by(user, options = {})
        relation = user.listing_saves
        if options[:limit].present?
          relation = relation.limit(options[:limit])
        end
        if options[:exclude_sellers].present?
          exclude_seller_ids = Array.wrap(options[:exclude_sellers]).compact.map { |u| u.is_a?(User) ? u.id : u }
          relation = relation.joins(:listing).
                              where("#{Listing.quoted_table_name}.seller_id NOT IN (?)", exclude_seller_ids)
        end
        relation.order("#{ListingCollectionAttachment.quoted_table_name}.created_at DESC")
      end

      def recently_saved_by_ids(user, options = {})
        recently_saved_by(user, options).select("DISTINCT #{ListingCollectionAttachment.quoted_table_name}.listing_id").
          map(&:listing_id)
      end
    end
  end
end
