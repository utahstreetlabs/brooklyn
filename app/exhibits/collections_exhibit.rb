class CollectionsExhibit < Exhibitionist::Exhibit
  include Exhibitionist::RenderedWithHelper
  set_helper :create_collection_modal_content

  def args
    [self]
  end
end
