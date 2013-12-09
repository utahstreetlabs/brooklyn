class Api::Listings::PhotosController < ApiController
  respond_to :xml, :json

  before_filter only: [:index, :create, :count, :update, :order, :destroy] do
    @listing = Listing.find_by_slug!(params[:listing_id], include: :photos)
    # XXX: require that the current token's user is the seller
  end

  def index
    # XXX: why the listing instead of its list of photos?
    respond_with(@listing)
  end

  def create
    # XXX: wtb user error handling
    photo = params[:listing_photo] || params[:listing][:photo] || {link: {}}
    if photo.is_a?(ActionDispatch::Http::UploadedFile)
      @listing_photo = @listing.add_uploaded_photo!(photo)
    else
      @listing_photo = @listing.add_remote_photo!(photo[:source_uid], photo[:link][:href])
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
    @listing.photos.find_by_uuid!(params[:id]).destroy
    render(nothing: true, status: 204)
  end

  def order
    params[:listing_photos] = params[:listing_photos][:photo] if params[:listing_photos].is_a?(Hash)
    uuids = params[:listing_photos].map { |lp| lp['id'] }
    @listing.reorder_photos_by_uuid(uuids)
    render(nothing: true, status: 204)
  end

  def count
    render_jsend(success: {count: @listing.photos.count })
  end
end

