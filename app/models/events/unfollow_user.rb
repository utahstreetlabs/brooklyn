module Events
  class UnfollowUser < Base
    set_event_name 'unfollow user'

    def initialize(follower, followee, properties = {})
      @properties = {follower_id: follower.id, followee_id: followee.id}.merge(properties)
    end

    def self.complete_properties(props)
      follower = User.find(props.delete(:follower_id))
      followee = User.find(props.delete(:followee_id))
      props[:follower] = follower.slug
      props[:followee] = followee.slug
      props.merge(followee_properties(followee))
    end
  end
end
