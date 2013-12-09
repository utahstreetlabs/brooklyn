module Collections
  class DropdownMenuExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithHelper
    set_helper :collection_dropdown_menu
    set_virtual_path 'collections/dropdown_menu'
    attr_reader :collections

    def initialize(collections, viewer, context)
      super(collections, viewer, context)
      @collections = collections
    end

    def args
      [collections]
    end
  end
end
