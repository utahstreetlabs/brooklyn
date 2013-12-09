class Listings::InstagramPhotosController < ApplicationController
  class InstagramPhotoUrlInvalid < Exception; end
  class InstagramPhotoNotSaved < Exception; end

  include Controllers::ListingScoped
  include Controllers::PhotoScoped
  include Controllers::InstagramProfileScoped
  include Controllers::Jsendable

  set_listing :only => [:index, :update]
  require_instagram_connection
  set_instagram_profile
  require_seller :redirect => :listing
  respond_to :json, :only => [:index, :update]

  # Returns a set of photos from a user's instagram recent media feed.
  # @param [Hash] params parameters passed to rubicon to fetch recent media data.
  # @option params [Integer] :count number of items to fetch from the feed.
  # @option params [Integer] :max_id fetch results with id less than (i.e. older than) this value.
  def index
    count = (params[:count] || 20).to_i

    options = {count: count}
    options[:max_id] = params[:max_id] if params[:max_id]

    response = current_user.person.for_network(:instagram).photos(options)
    @photos = response.values
    # pagination is the lowest id -- that is, the oldest id -- fetched.
    # The next page of results pulled will be those older (less than) this id.
    @pagination = response.keys.sort_by {|k| k.to_i}.first
    respond_to do |format|
      format.json do
        photos = @photos.map do |p|
          {ui: render_to_string(partial: '/listings/instagram_import.html', locals: {listing: @listing, photo: p}),
           id: p['id']}
        end
        results = {results: photos}
        results.merge!({more: listing_instagram_index_path(@listing, count: 12, max_id: @pagination)}) if @pagination
        render_jsend(success: results)
      end
      format.html do
        render layout: !request.xhr?
      end
    end
  end

  # Imports an instagram photo from a provided url if the photo
  # has not already been imported.  Returns an error if the photo
  # has already been imported for this listing.
  # @param [Hash] params parameters for photo import from recent media feed
  # @option params [String] :id instagram uid of photo to import
  # @option params [String] :url url of photo to import from instagram
  def update
    unless @listing.has_sourced_photo?(params[:id])
      begin
        @photo = @listing.photos.build(source_uid: params[:id])
        import_photo(params[:url])
        respond_with_jsend photos_jsend
      rescue ActiveRecord::RecordNotSaved
        respond_with_jsend fail: 'Could not save photo', code: 422, data: {errors: @photo.errors}
      rescue InstagramPhotoUrlInvalid
        respond_with_jsend error: 'Photo url does not have valid URL scheme', code: 400
      end
      return
    end
    respond_with_jsend error: 'Photo exists', code: 409
  end

  protected

  def import_photo(url)
    raise InstagramPhotoUrlInvalid unless url.start_with?('http')
    @photo.file.download!(url)
    @photo.save!
  end
end
