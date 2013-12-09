module Events
  class CollectionDelete < Base
    set_event_name 'collection delete'

    def initialize(collection, properties = {})
      # have to pull properties out in advance since the collection won't be queryable by the time
      # +complete_properties+ is called.
      @properties = properties.merge(self.class.collection_properties(collection.id, collection: collection,
                                                                      viewer: collection.user))
    end

    def self.complete_properties(props)
      props
    end
  end
end
