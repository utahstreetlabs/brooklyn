module Events
  class CollectionView < Base
    set_event_name 'collection view'

    def initialize(viewer, collection, properties = {})
      @properties = properties
      @properties[:viewer_id] = viewer.id if viewer
      @properties[:collection_id] = collection.id
    end

    def self.complete_properties(props)
      props.merge(collection_properties(props.delete(:collection_id), viewer_id: props.delete(:viewer_id)))
    end
  end
end
