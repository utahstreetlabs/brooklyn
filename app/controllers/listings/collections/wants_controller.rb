class Listings::Collections::WantsController < ApplicationController
  include Controllers::ListingScoped
  include Controllers::Jsendable
  respond_to :json
  set_flash_scope 'listings.collections.wants'
  set_listing

  before_filter do
    @collection = current_user.find_collection_by_slug!(params[:collection_id])
  end

  def create
    want = current_user.wants_item!(@listing.item, want_params)
    respond_with_jsend(success: {
      followupModal: view_context.save_listing_to_collection_success_modal(@listing)
    })
  rescue ActiveRecord::RecordInvalid => e
    respond_with_jsend(fail: {
      modal: view_context.want_listing_modal_content(@listing, @collection, e.record)
    })
  end

  def update
    want = current_user.find_want_by_id(params[:id])
    if want.update_attributes(want_params)
      respond_with_jsend(success: {
        followupModal: view_context.save_listing_to_collection_success_modal(@listing)
      })
    else
      respond_with_jsend(fail: {
        modal: view_context.want_listing_modal_content(@listing, @collection, want)
      })
    end
  end

  def complete
    respond_with_jsend(success: {
      followupModal: view_context.save_listing_to_collection_success_modal(@listing)
    })
  end

  protected
    def want_params
      (params[:want] || {}).slice(:max_price, :condition, :notes)
    end
end
