module Users
  module Collections
    extend ActiveSupport::Concern
    include Stats::Trackable

    included do
      has_many :collections, dependent: :destroy
      has_many :collection_listings, through: :collections, source: :listings
      has_many :collection_follows, dependent: :destroy
      has_many :followed_collections, through: :collection_follows, source: :collection
    end

    def find_collection_by_slug(slug)
      Collection.find_collections_by_slug(slug, user: self).first
    end

    def find_collection_by_slug!(slug)
      find_collection_by_slug(slug) or raise ActiveRecord::RecordNotFound.new("Collection #{slug}")
    end

    def find_collections_by_slug(slugs)
      Collection.find_collections_by_slug(slugs, user: self)
    end

    def find_collection_by_name(name)
      Collection.find_named_for_user(name, self)
    end

    def find_collection_by_name!(name)
      find_collection_by_name(name) or raise ActiveRecord::RecordNotFound.new("Collection named #{name}")
    end

    def has_named_collection?(name)
      Collection.named_exists_for_user?(name, self)
    end

    def create_default_collections!
      Collection.create_defaults_for(self)
    end

    def collections_count
      collections.count
    end

    def following_collection?(collection)
      collection_follow_of(collection).exists?
    end

    def collection_follow_of(collection)
      CollectionFollow.where(user_id: self.id, collection_id: collection.id)
    end

    def autofollow_collections
      Collection.autofollow_list_for_interests(interests)
    end

    def follow_collection!(collection)
      begin
        collection_follows.create!(collection: collection)
      rescue ActiveRecord::RecordNotUnique
        # ignore for now - this means the follow already exists
      end
    end

    def follow_autofollow_collections
      autofollow_collections.each do |autofollow_collection|
        follow_collection!(autofollow_collection)
      end
    end

    def save_listing_to_collections(listing, collections)
      listing.collections += collections
    end

    def unowned_collection_follows
      relation = collection_follows.includes(:collection)
      relation = relation.where("#{Collection.quoted_table_name}.user_id != ?", self.id)
      relation.order("#{CollectionFollow.quoted_table_name}.created_at DESC")
    end

    def unowned_collection_follows_count
      collection_follows.joins(:collection).where("#{Collection.quoted_table_name}.user_id != ?", self.id).count
    end

    def followed_collections_reverse_chron
      collection_follows.includes(:collection).sort { |a, b| b.created_at <=> a.created_at }.map(&:collection)
    end

    # Returns the a hash from collection ids to whether or not the user is
    # following that collection.
    #
    # @return [Hash] a map of collection ids to booleans
    def collection_followings(collection_ids)
      collection_ids = Array.wrap(collection_ids).compact.uniq
      CollectionFollow.
        select('collection_id, count(*) AS follow_count').
        where(collection_id: collection_ids).
        where(user_id: self.id).
        group(:collection_id).
        each_with_object({}) { |a, m| m[a.collection_id] = (a.follow_count > 0) }
    end

    def unfollow_collection!(collection)
      collection_follow_of(collection).destroy_all
    end

    #XXX: if we add user_id to LCA, drop the join
    def listing_saves
      ListingCollectionAttachment.joins(:collection).where(collections: {user_id: self.id})
    end

    def saves_for_listings(listing_ids)
      listing_saves.where(listing_id: listing_ids)
    end

    def saves_for_listing(listing_id)
      saves_for_listings([listing_id])
    end

    def saved?(listing)
      saves_for_listing(listing.id).any?
    end

    # @see +Listing.find_liked_listings_not_already_in_owned_collections+
    def liked_listings_not_already_in_owned_collections(options = {})
      Listing.find_liked_not_already_in_owned_collections(self, options)
    end

    # @see +Listing.recently_added_listings_from_followed_collections+
    def recently_created_listings_from_followed_collections(options = {})
      Listing.find_recently_created_from_followed_collections(self, options)
    end

    def recently_created_interesting_listings(options = {})
      Listing.find_recently_created_interesting(self, options)
    end

    module ClassMethods
      def collection_counts(user_ids)
        Collection.where(user_id: user_ids).count(group: :user_id)
      end
    end
  end
end
