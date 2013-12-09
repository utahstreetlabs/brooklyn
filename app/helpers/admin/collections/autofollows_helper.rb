require 'exhibitionist'

module Admin
  module Collections
    module Autofollows

      class CollectionExhibit < Exhibitionist::Exhibit
        include Exhibitionist::RenderedWithPartial
          set_partial '/admin/collections/collection_info.html'

        def locals
          {collection: self}
        end
      end
    end
  
    module AutofollowsHelper
      # required by Rails for autoloading
    end
  end
end
