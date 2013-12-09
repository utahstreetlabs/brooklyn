class Collections::ListingsController < ApplicationController
  include Controllers::Jsendable
  respond_to :json
  set_flash_scope 'collections.listings'
  before_filter :load_listing, :load_collection

  def create
    @collection.add_listing(@listing)
    respond_with_jsend(:success)
  end

  def destroy
    @collection.remove_listing(@listing)
    respond_with_jsend(success: {refresh: view_context.product_card_removed_from_collection_message})
  end

  protected

    # used for all actions since they are all scoped to the collection
    def load_collection
      @collection = current_user.collections.find_by_slug(params[:collection_id]) ||
        respond_with_jsend(fail: {message: localized_flash_message(:no_collection)})
    end

    def load_listing
      @listing = Listing.find_by_slug(params[:id]) ||
        respond_with_jsend(fail: {message: localized_flash_message(:no_listing)})
    end
end
