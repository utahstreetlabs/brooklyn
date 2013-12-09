require 'active_support/concern'

module Users
  # Stashes key/value attributes in a Redis hash. Those supported include "last_accessed", which denotes the last
  # time the user accessed the application, and "last_synced", which is the last time the user's network profile
  # attributes were synced.
  #
  # The stash is set to expire automatically +#stash_seconds+ after the user's last access. Groups of stashes
  # older than a certain amount of time can be manually purged with +#delete_inactive_stashes+.
  module KeyValueStash
    extend ActiveSupport::Concern
    include Ladon::ErrorHandling

    LAST_ACCESSED_KEY = :last_accessed
    LAST_SYNCED_KEY   = :last_synced

    included do
      hash_key :stash
      value :last_feed_refresh
    end

    # Stashes the current time under +LAST_ACCESSED_KEY+ and resets the stash's expiration time.
    def touch_last_accessed
      self.class.with_error_handling('Updating last_accessed') do
        rv = stash[self.class::LAST_ACCESSED_KEY] = self.class.to_timestamp(Time.zone.now.utc)
        stash.expire(self.class.stash_seconds)
        rv
      end
    end

    def last_accessed
      self.class.with_error_handling('Fetching last_accessed') do
        stash[self.class::LAST_ACCESSED_KEY]
      end
    end

    # Stashes the current time under +LAST_SYNCED_KEY+.
    def touch_last_synced
      self.class.with_error_handling('Updating last_synced') do
        stash[self.class::LAST_SYNCED_KEY] = self.class.to_timestamp(Time.zone.now.utc)
      end
    end

    def last_synced
      self.class.with_error_handling('Fetching last_synced', default_to_now) do
        stash[self.class::LAST_SYNCED_KEY]
      end
    end

    def set_last_feed_refresh_time(time)
      self.class.with_error_handling("Unable to set last feed refresh to #{time}") do
        redis.multi do
          last_feed_refresh.value = self.class.to_timestamp(time.utc)
          last_feed_refresh.expire(self.class.feed_refresh_expire_seconds)
        end
      end
    end

    def last_feed_refresh_time
      self.class.with_error_handling('Unable to get last feed refresh time', default_to_now) do
        # if a user has never requested the feed or their stash has expired, just set the time to current
        # that way they have a 0 count of new stories until something new comes in
        if (stringified = last_feed_refresh.value)
          self.class.from_timestamp(stringified)
        else
          timestamp = Time.zone.now
          self.set_last_feed_refresh_time(timestamp)
          timestamp
        end
      end
    end

    def clear_stash
      self.class.with_error_handling('Clearing stash') do
        stash.clear
      end
    end

    module ClassMethods
      def stash_seconds
        Brooklyn::Application.config.users.stash.expire_secs
      end

      def sync_seconds
        Brooklyn::Application.config.users.stash.sync_update_profile_secs
      end

      def feed_refresh_expire_seconds
        Brooklyn::Application.config.users.stash.feed_refresh_expire_secs
      end

      # Deletes the stash of every user whose last access was more than +seconds+ ago.
      #
      # @return the total number of stashes deleted
      def delete_inactive_stashes!(seconds)
        with_error_handling('Deleting inactive stashes') do
          find_stash_keys_for_stale_timestamp(LAST_ACCESSED_KEY, seconds).inject(0) do |m, k|
            m += redis.del(k)
          end
        end
      end

      # Returns the users whose last sync was more than +seconds+ ago.
      #
      # @return [ActiveRecord::Relation]
      def unsynced(seconds)
        with_stale_stash_timestamp(LAST_SYNCED_KEY, seconds)
      end

      # Searches all user stashes, deleting those where the access timestamp is stale and yielding those where the
      # sync timestamp is stale.
      #
      # @see #stale_timestamp?
      def each_unsynced_after_deleting_inactive(seconds = nil, &block)
        with_error_handling('Finding unsynced') do
          sync_seconds ||= self.sync_seconds
          stash_keys.find_all do |key|
            last_access, last_sync = redis.hmget(key, LAST_ACCESSED_KEY, LAST_SYNCED_KEY)
            if stale_timestamp?(last_access, self.stash_seconds)
              redis.del(key)
            elsif stale_timestamp?(last_sync, sync_seconds)
              begin
                user = self.find((key.split(':')[1]).to_i)
                yield user
              rescue
              end
            end
          end
        end
      end

      # Returns users whose stash timestamp attribute +attribute_key+ is stale.
      #
      # @return [ActiveRecord::Relation]
      # @see #stale_timestamp?
      def with_stale_stash_timestamp(attribute_key, seconds = 0)
        where(id: find_stash_keys_for_stale_timestamp(attribute_key, seconds).map { |k| k.split(':')[1].to_i })
      end

      # Returns each stash key whose timestamp attribute +attribute_key+ is stale.
      #
      # @return [Array]
      # @see #stale_timestamp?
      def find_stash_keys_for_stale_timestamp(attribute_key, seconds = 0)
        # this scans the entire key set, so this operation will get slower as the number of users grows.
        stash_keys.find_all {|key| stale_timestamp?(redis.hget(key, attribute_key), seconds)}
      end

      # Returns all stash keys
      #
      # @return [Array]
      def stash_keys
        with_error_handling('Getting stash keys', additionally: lambda { [] }) do
          redis.keys("#{redis_prefix}:*:stash")
        end
      end

      # Returns whether or not the given value is a stale timestamp. This is true when the value is blank or when it is
      # older than +seconds+ ago.
      #
      # XXX: it is questionable whether or not a blank value should be considered stale. The answer probably
      # depends on the specific attribute. The class should be able to designate whether or not a particular attribute
      # considers a blank value stale.
      #
      # @return [Boolean]
      def stale_timestamp?(value, seconds)
        begin
          value.blank? || Time.zone.now.utc > from_timestamp(value).advance(seconds: seconds)
        rescue # not a timestamp value
          false
        end
      end

      # @param [DateTime] datetime
      # @return [String]
      def to_timestamp(datetime)
        datetime.to_s
      end

      # @param [String] timestamp
      # @return [DateTime]
      def from_timestamp(timestamp)
        DateTime.strptime(timestamp, "%F %T %z")
      end
    end

    protected

      # returns params appropriate for use with with_error_handling
      # that will just return the current time if an error is returned
      def default_to_now
        { additionally: lambda { Time.zone.now.utc } }
      end
  end
end
