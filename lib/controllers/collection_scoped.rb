module Controllers
  # Provides common behaviors for controllers that are scoped to a collection.
  module CollectionScoped
    extend ActiveSupport::Concern

    module ClassMethods
      def load_collection(options = {})
        before_filter(options) do
          load_collection or respond_to do |format|
            format.json { respond_with_jsend(fail: {message: localized_flash_message(:no_collection)}) }
          end
        end
      end
    end

    protected

      def load_collection
        @collection = Collection.find(params[:collection_id] || params[:id])
      end
  end
end
