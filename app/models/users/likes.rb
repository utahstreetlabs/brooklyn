require 'active_support/concern'
require 'pyramid/models/user/likes'

module Users
  module Likes
    extend ActiveSupport::Concern

    # Returns a subset of likes for likeables that the user likes.
    #
    # @return [Ladon::PaginatableArray] of +Pyramid::Like+
    # @see Pyramid::User::Likes#find
    def likes(options = {})
      logger.debug("Finding likes by user #{self.id}")
      Pyramid::User::Likes.find(self.id, options)
    end

    def all_liked_listing_ids(options = {})
      Ladon::PaginatedCollection.new do |paging_opts|
        self.likes(paging_opts.reverse_merge(attr: [:listing_id], per: options[:count] || 5))
      end.map(&:listing_id)
    end

    # Returns the total number of likeables that the user likes.
    #
    # @return [Integer]
    # @see Pyramid::User::Likes#count
    def likes_count(options = {})
      logger.debug("Counting likes by user #{self.id}")
      Pyramid::User::Likes.count(self.id, options)
    end

    # Returns a subset of all types of likeables that the user likes.
    #
    # @param [Hash] options
    # @option options [Hash] +listing options to pass to +Listing#likeable+
    # @option options [Hash] +tag options to pass to +Tag#likeable+
    # @return [Ladon::PaginatableArray] of +Listing+ and +Tag+
    # @see #likes for other options
    # @see Listing#likeable
    # @see Tag#likeable
    def liked(options = {})
      likes = self.likes(options)

      # build an index of listing and tag ids so we can query for the listings and tags later
      id_idx = likes.each_with_object({listing: [], tag: []}) do |like, m|
        if like.listing_id
          m[:listing] << like.listing_id
        elsif like.tag_id
          m[:tag] << like.tag_id
        end
      end

      # query for the liked listings and build a lookup table
      listing_ids = id_idx[:listing].compact.uniq.sort
      listings = listing_ids.any?? Listing.like_visible(listing_ids, options.fetch(:listing, {})) : {}
      listing_idx = listings.group_by(&:id)

      # query for the liked tags and build a lookup table
      tag_ids = id_idx[:tag].compact.uniq.sort
      tags = tag_ids.any?? Tag.like_visible(tag_ids, options.fetch(:tag, {})) : {}
      tag_idx = tags.group_by(&:id)

      # map the ordered list of likes to their corresponding listings/tags
      likeables = likes.map do |like|
        if like.listing_id
          listing_idx[like.listing_id].first if listing_idx[like.listing_id]
        elsif like.tag_id
          tag_idx[like.tag_id].first if tag_idx[like.tag_id]
        end
      end.compact.uniq

      Ladon::PaginatableArray.new(likeables, offset: likes.offset_value, limit: likes.limit_value,
        total: likes.total_count)
    end

    # Returns this user's like for the specified likeable, if any.
    #
    # @return [Pyramid::Like] or +nil+ if no such like exists
    # @see Pyramid::User::Likes#get
    def like_for(likeable, options = {})
      logger.debug("Getting like of #{likeable.likeable_type} #{likeable.id} by user #{self.id}")
      Pyramid::User::Likes.get(self.id, likeable.likeable_type, likeable.id, options)
    end

    # Returns whether or not the user likes the specified likeable.
    #
    # @return [Boolean]
    # @see Pyramid::User::Likes#get
    def likes?(likeable)
      like_for(likeable, attrs: [:id]) != nil
    end

    # Returns whether or not the specified likeables are liked by a given user.
    #
    # @return [Hash of likeable id attr => Boolean]
    # @see Pyramid::User::Likes#existences
    def like_existences(likeable_type, likeable_ids, options = {})
      logger.debug("Finding existences of #{likeable_type} #{likeable_ids} by user #{self.id}")
      Pyramid::User::Likes.existences(self.id, likeable_type, likeable_ids, options)
    end

    # Creates a like of the specified likeable by this user if one does not already exist.
    #
    # @return [Pyramid::Like] or +nil+ if the like could not be created
    # @see Pyramid::User::Likes#create
    def like(likeable, options = {})
      logger.debug("Creating like of #{likeable.likeable_type} #{likeable.id} by user #{self.id}")
      like = Pyramid::User::Likes.create(self.id, likeable.likeable_type, likeable.id, options)
      likeable.notify_observers(:after_like, self, like, options) if like
      like
    end

    # Deletes any existing like of the specified likeable by this user.
    #
    # @see Pyramid::User::Likes#destroy
    def unlike(likeable, options = {})
      logger.debug("Destroying like of #{likeable.likeable_type} #{likeable.id} by user #{self.id}")
      Pyramid::User::Likes.destroy(self.id, likeable.likeable_type, likeable.id, options)
      likeable.notify_observers(:after_unlike, self, options)
    end

    module ClassMethods
      # Returns the total number of likes for likeables for each user.
      #
      # @return [Hash of user id => Integer]
      # @see Pyramid::User::Likes#count_many
      def like_counts(user_ids, options = {})
        logger.debug("Counting likes by users #{user_ids}")
        Pyramid::User::Likes.count_many(user_ids, options)
      end
    end
  end
end
