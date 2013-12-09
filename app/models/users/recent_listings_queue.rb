require 'active_support/concern'
require 'redis/objects'

module Users
  # Caches a queue of listing ids representing listings that have been recently associated with the user through
  # an action such as creating the listing, liking it, sharing it, etc. The queue has a fixed size; if it is full when
  # a listing id is enqueued in response to the user taking an action on the listing, then the id at the head of the
  # queue is dequeued (but not used in any way, just dropped). Thus, the queue always denotes the most recently acted
  # upon listings in chronological order of action.
  module RecentListingsQueue
    extend ActiveSupport::Concern

    included do
      list :recent_listing_ids, maxlength: recent_listing_queue_size
      list :recent_listed_listing_ids, maxlength: recent_listing_queue_size
      list :recent_saved_listing_ids, maxlength: recent_listing_queue_size
    end

    # Fills the recent listed listing ids queues based on the listings the user has listed.
    #
    # @return [Array] the recently listed listing ids
    def fill_recent_listed_listing_ids
      recent_listed_listing_ids.clear
      Listing.recently_listed_by_ids(self, limit: self.class.recent_listing_queue_size).each do |id|
          recent_listed_listing_ids << id
      end
      recent_listed_listing_ids.values
    end

    # Fills the recent saved listing ids queues based on the listings the user has saved.
    #
    # @return [Array] the recently saved listing ids
    def fill_recent_saved_listing_ids
      recent_saved_listing_ids.clear
      Listing.recently_saved_by_ids(self, limit: self.class.recent_listing_queue_size).each do |id|
          recent_saved_listing_ids << id
      end
      recent_saved_listing_ids.values
    end

    # Fills the recent listing ids queues based on the listings the user has loved.
    #
    # @return [Array] the recently loved listing ids
    def fill_recent_loved_listing_ids
      recent_listing_ids.clear
      Listing.liked_by_ids(self, per: self.class.recent_listing_queue_size).each do |id|
        recent_listing_ids << id
      end
      recent_listing_ids.values
    end

    module ClassMethods
      def recent_listing_queue_size
        Brooklyn::Application.config.users.recent_listings.queue_size
      end
    end
  end
end
