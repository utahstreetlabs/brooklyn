require 'resque'
require 'resque-retry'
require 'ladon'

# XXX: if we ever implement autofollow for other networks, generalize this

class FacebookAutoFollowNotReadyException < Exception; end

module Facebook
  class FollowRegisteredFriends < Ladon::Job
    extend Resque::Plugins::Retry
    @queue = :facebook

    @retry_limit = 3
    @retry_delay = 60

    def self.work(user_id)
      user = User.with_person(user_id)
      if user
        if user.registered?
          profile = user.person.for_network(:facebook)
          if profile && profile.synced?
            Rails.logger.debug("Following registered facebook followers for user #{user.id}")
            user.follow_registered_network_followers!(profile)
            user.follow_inviters!(profile)
          else
            Rails.logger.warn("Unable to follow registered Facebook friends for user %s which has no Facebook profile" %
              [user.id])
            raise FacebookAutoFollowNotReadyException unless Resque.inline
          end
        else
          raise FacebookAutoFollowNotReadyException unless Resque.inline
        end
      else
        Rails.logger.warn("Unable to follow registered Facebook friends for user #{user_id} which does not exist")
      end
    end
  end
end
