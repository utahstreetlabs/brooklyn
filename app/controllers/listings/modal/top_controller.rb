class Listings::Modal::TopController < ApplicationController
  include Controllers::ListingScoped

  set_listing
  respond_to :json
  before_filter :load_collection

  def show
    track_usage(Events::ListingModalView.new(@listing))
    render_jsend(success: {
      modalTop: Listings::Modal::TopExhibit.new(@listing, current_user, view_context, collection: @collection).render,
      saveManager: Listings::SaveManagerExhibit.new(@listing, current_user, view_context,
        collections: current_user.collections, source: 'listing_modal').render,
      url: listing_path(@listing)
    })
  end

  protected
    def load_collection
      @collection = Collection.find(params[:collection]) if params[:collection]
    end
end
