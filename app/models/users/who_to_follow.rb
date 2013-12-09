require 'active_support/concern'
require 'lagunitas/models/preferences'

module Users
  module WhoToFollow
    extend ActiveSupport::Concern

    def follow_suggestion_blacklist
      preferences.follow_suggestion_blacklist
    end

    # Returns users we suggest that this user follow based on shared interests. Excludes those users on the user's
    # follow suggestion blacklist as well as those users blocked by this user.
    #
    # @option options [Array] :blacklist (+[]+) a list of user ids to exclude from the query
    # @option options [Boolean] :only_count (+false+) if truthy, returns a count instead of a list of users
    # @option options [Integer] :offset (0) the number of records to skip
    # @option options [Boolean] :random (+false+) if truthy, returns a random sample of records, otherwise orders the
    #                                             results by suggestion position
    # @return [Array] of +User+s or [Integer] count
    # @see +#follow_suggestion_blacklist+
    def follow_suggestions(limit = 3, options = {})
      blacklist = options[:blacklist] || []
      blacklist += follow_suggestion_blacklist
      blacklist << id

      select = options[:only_count?] ? "count(1) as id" : "u.*"
      offset = options[:offset] ? options[:offset] * limit : 0
      order_by = options[:random] ? 'RAND()' : 'us.position'

      # Cap out infinite scroll at 100 followers.
      limit = options[:only_count?] ? 100 : limit

      # This monster query:
      # - gets a list of suggested users with shared interests that the current user is not following
      # - excludes any users in the blacklist (which should include the current user)
      # - filters for registered users
      # - orders [descending] by the number of active listings each user has
      # - applies the given limit
      sql = <<-SQL
        SELECT DISTINCT #{select}
          FROM users u JOIN
               user_suggestions us ON us.user_id = u.id JOIN
               user_interests ui ON (us.interest_id = ui.interest_id AND ui.user_id = :user_id)
         WHERE us.user_id NOT IN (
               SELECT user_id FROM follows WHERE follower_id = :user_id
                UNION
               SELECT blocker_id FROM blocks WHERE user_id = :user_id
                UNION
               SELECT user_id FROM blocks WHERE blocker_id = :user_id
               )
           AND us.user_id NOT IN (:blacklist)
      ORDER BY #{order_by}
        LIMIT :limit
        OFFSET :offset
      SQL
      query = self.class.find_by_sql([sql, {user_id: self.id, blacklist: blacklist, limit: limit, offset: offset}])
      options[:only_count?] ? query.first.id : query
    end

    def blacklist_follow_suggestion(user_id)
      Lagunitas::Preferences.add(id, :follow_suggestion_blacklist, user_id)
    end
  end
end
