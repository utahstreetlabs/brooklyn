module Events
  class CollectionUpdate < Base
    set_event_name 'collection update'

    def initialize(collection, properties = {})
      @properties = properties
      @properties[:collection_id] = collection.id
      @properties[:viewer_id] = collection.user_id
    end

    def self.complete_properties(props)
      props.merge(collection_properties(props.delete(:collection_id), viewer_id: props.delete(:viewer_id)))
    end
  end
end
