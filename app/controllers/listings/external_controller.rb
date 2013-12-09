class Listings::ExternalController < ApplicationController
  skip_enable_autologin
  before_filter :load_listing_source

  def new
    @listing = ExternalListing.find_with_url(@source.url)
    if @listing.present? && created_from_bookmarklet?
      # When adding an external listing that already exists, instead of adding another copy of the listing
      # we add a like from the current user and then allow them to save the listing to a collection (and
      # comment on it, add a price alert, etc.)
      current_user.like(@listing)
      return redirect_to(listing_bookmarklet_collections_path(@listing))
    end
    @listing = ExternalListing.new_from_source(@source)
  end

  def create
    @listing = ExternalListing.new(listing_params)
    @listing.add_to_collection_slugs = params[:collection_slugs]
    @listing.source = @source
    @listing.seller = current_user
    begin
      if @listing.save
        if listing_params[:source] == 'bookmarklet'
          redirect_to(listing_bookmarklet_collections_path(@listing))
        else
          redirect_to(listing_path(@listing))
        end
      else
        render(:new)
      end
    rescue StateMachine::InvalidTransition
      if @listing.errors.any?
        set_flash_message(:alert, :not_saved, errors: @listing.errors.full_messages.join(', '))
      end
      render(:new)
    end
  end

  protected
    def load_listing_source
      @source = ListingSource.find_by_uuid!(params[:uuid])
    end

    def listing_params
      params[:listing].slice(:title, :category_slug, :price, :initial_comment, :source_image_id,
                             :source, :add_to_collection_slugs, :description)
    end

    def created_from_bookmarklet?
      params[:source] == 'bookmarklet'
    end
end
