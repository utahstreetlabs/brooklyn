class Api::ListingsController < ApiController
  respond_to :xml, :json

  before_filter only: [:show, :update, :destroy, :activate] { @listing = Listing.find_by_slug!(params[:id]) }

  def index
    search_options = params.symbolize_keys.slice(:seller_id, :sort, :page, :per_page, :created_after, :with_sold)
    listings = ListingSearcher.new(search_options.reverse_merge(seller_id: @user.id, with_sold: true)).all
    respond_with({ listings: listings.map { |l| l.api_hash(summary: true) } })
  end

  def show
    respond_with({ listing: @listing.api_hash })
  end

  def create
    @listing = InternalListing.new
    @listing.seller = @user
    @listing = set_listing_attrs(@listing)
    @listing.save!

    # has to be done after saving the listing so that the listing has an id
    photos = params[:listing][:photos] || params[:listing][:photo]
    if photos
      # if xml, photos show be a hash with a photo key
      photos = photos[:photo] if photos.is_a?(Hash)

      Array.wrap(photos).each do |photo|
        if photo.is_a?(ActionDispatch::Http::UploadedFile)
          @listing.add_uploaded_photo!(photo)
        else
          @listing.add_remote_photo!(photo['source_uid'], photo['link']['href'])
        end
      end
    end

    if @listing.has_photos?
      @listing.complete!
      @listing.activate!
    end

    if !!params[:empty]
      headers['Link'] = %Q{<#{listing_url(@listing)}>; rel="related"; type="text/html"; title="#{@listing.title}"}
      entity = ''
    else
      entity = @listing.api_hash(summary: true)
    end
    respond_with(entity, status: 201, location: api_listing_url(@listing))
  end

  def update
    @listing = set_listing_attrs(@listing)
    @listing.save!
    render(nothing: true, status: 204)
  end

  def destroy
    @listing.cancel!
    render(nothing: true, status: 204)
  end

  def activate
    @listing.complete! unless @listing.inactive?
    @listing.activate!
    render(nothing: true, status: 204)
  end

  def count
    render_jsend success: {count: @user.seller_listings.count }
  end

protected
  def set_listing_attrs(current_listing)
    listing_attr = params[:listing] || {}
    listing_attr[:category_slug] = listing_attr.delete(:category)
    listing_attr[:size_name] = listing_attr.delete(:size)
    listing_attr[:brand_name] = listing_attr.delete(:brand)
    listing_attr[:shipping] = 0 unless listing_attr.has_key?('shipping')

    tags = listing_attr.delete(:tags)
    tags = tags.fetch(:tag, []) if tags.is_a?(Hash)
    current_listing.tags = Tag.find_or_create_all_by_name(tags)
    condition = listing_attr.delete(:condition)
    current_listing.source_uid = listing_attr[:source_uid].present?? listing_attr.delete(:source_uid) : nil
    current_listing.attributes = listing_attr
    current_listing.condition = condition

    current_listing
  end
end
