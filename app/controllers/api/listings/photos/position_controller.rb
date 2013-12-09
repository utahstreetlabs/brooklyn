class Api::Listings::Photos::PositionController < ApiController
  respond_to :xml, :json

  before_filter only: [:show, :update, :destroy] do
    @listing = Listing.find_by_slug!(params[:listing_id], include: :photos)
    @photo = @listing.photos.find_by_position!(params[:id])
  end

  def show
    respond_with @photo
  end

  def update
    new_photo = params[:listing_photo] || params[:listing][:photo] || {link: {}}
    if new_photo.is_a?(ActionDispatch::Http::UploadedFile)
      @listing_photo = @photo.update_uploaded_photo!(new_photo)
    else
      @listing_photo = @photo.update_remote_photo!(new_photo[:source_uid], new_photo[:link][:href])
    end

    if params[:empty]
      headers['Link'] = %Q{<#{listing_photo_url(@listing, @listing_photo)}>}
      entity = ''
    else
      entity = @listing_photo
    end

    respond_with(entity, status: 201, location: absolute_url(@listing_photo.file.large.url, root_url: root_url))    
  end

  def destroy
    @photo.destroy
    render(nothing: true, status: 204)
  end
end

