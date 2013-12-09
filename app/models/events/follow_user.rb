module Events
  class FollowUser < Base
    set_event_name 'follow user'

    def initialize(follow, properties = {})
      @properties = {follow_id: follow.id}.merge(properties)
    end

    def self.complete_properties(props)
      follow = Follow.find(props.delete(:follow_id))
      props[:follower] = follow.follower.slug
      props[:followee] = follow.user.slug
      props[:follow_type] = follow.class.name
      props.merge(followee_properties(follow.user))
    end
  end
end
