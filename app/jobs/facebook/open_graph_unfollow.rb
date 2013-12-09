require 'ladon'

module Facebook
  class OpenGraphUnfollow < OpenGraphJob
    @queue = :facebook

    def self.work(user_id, subscription_id)
      with_error_handling("facebook open graph unfollow", user_id: user_id, subscription_id: subscription_id) do
        profile = User.find(user_id).person.for_network(:facebook)
        profile.facebook_delete(url: subscription_id)
      end
    end
  end
end
