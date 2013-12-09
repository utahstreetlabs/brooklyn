class Listings::PhotosController < ApplicationController
  include Controllers::ListingScoped
  include Controllers::PhotoScoped
  include Controllers::Jsendable

  set_listing
  skip_requiring_login_only
  require_login_or_guest
  require_seller :redirect => :listing

  def new
  end

  def reorder
    @photo = @listing.photos.find(params[:photo_id])
    @photo.insert_at(params[:position].to_i)
    @photo.save
    respond_to do |format|
      format.json { render_jsend photos_jsend }
    end
  end

  def create
    listing_photo = params[:listing_photo] || {}
    photos_params = Array.wrap(listing_photo[:file]).map do |f|
      {background_processing: true}.merge(listing_photo).merge('file' => f)
    end
    @photos = @listing.photos.build(photos_params)
    process_and_render_photos_if(@photos) do
      @photos.map {|p| p.save }.all?
    end
  end

  def update
    @photo = ListingPhoto.find(params[:id])
    @photo.background_processing = true
    process_and_render_photos_if(@photo) { @photo.update_attributes(params[:listing_photo]) }
  end

  def destroy
    @listing.photos.destroy(params[:id])
    respond_to do |format|
      format.json { render_jsend photos_jsend }
    end
  end

  def make_primary
    @listing.photos.find(params[:photo_id]).move_to_top
    respond_to do |format|
      format.json { render_jsend photos_jsend }
    end
  end

  protected

  def process_and_render_photos_if(photos)
    photos = Array.wrap(photos)
    if yield
      photos.each { |photo| RecreatePhotoVersions.enqueue(:ListingPhoto, photo.id) }
      respond_with_jsend photos_jsend
    else
      respond_with_jsend error: 'Bad Request', code: 400, data: {errors: photos.map(&:errors)}
    end
  end
end
