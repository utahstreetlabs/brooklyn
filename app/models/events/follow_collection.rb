module Events
  class FollowCollection < Base
    set_event_name 'follow collection'

    def initialize(collection, follower, properties = {})
      @properties = {collection_id: collection.id, follower: follower.slug}.merge(properties)
    end

    def self.complete_properties(props)
      props.merge(collection_properties(props.delete(:collection_id)))
    end
  end
end
