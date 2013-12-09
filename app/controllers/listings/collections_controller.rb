class Listings::CollectionsController < ApplicationController
  include Controllers::ListingScoped
  include Controllers::Jsendable
  respond_to :json
  set_flash_scope 'listings.collections'
  set_listing

  def create
    collections = current_user.find_collections_by_slug(params[:collection_slugs])
    current_user.save_listing_to_collections(@listing, collections)
    save_price_alert
    leave_listing_comment
    respond_to_save(collections)
  end

  def update
    collections = current_user.find_collections_by_slug(params[:collection_slugs])
    @listing.update_collections_for(current_user, collections)
    save_price_alert
    leave_listing_comment
    respond_to_save(collections)
  end

  def save_modal
    collections = current_user.collections
    price_alert = current_user.price_alert_for(@listing) || current_user.build_price_alert(@listing)
    respond_with_jsend(success: {
      modal: view_context.save_listing_to_collection_modal_contents(@listing, collections, price_alert)
    })
  end

  protected

    def respond_to_save(collections)
      if params[:have] == "1"
        have = current_user.has_item!(@listing.item)
        followup = view_context.save_listing_to_collection_success_modal(@listing, have)
      elsif params[:want] == "1"
        want = current_user.want_for_item(@listing.item) || Want.new(max_price: @listing.price)
        collection = collections.first { |c| c.want? }
        followup = view_context.want_listing_modal(@listing, collection, want)
      else
        followup = view_context.save_listing_to_collection_success_modal(@listing)
      end
      respond_to do |format|
        format.html { redirect_to(params.fetch(:redirect, listing_path(@listing))) }
        format.json { respond_with_jsend(success: {
          followupModal: followup,
          saveButton: view_context.product_card_save_button(@listing, current_user.collections, collections.any?),
          listingId: @listing.id,
          stats: view_context.listing_stats(@listing.likes_count, @listing.saves_count),
          modalCtas: Listings::Modal::CtasExhibit.new(@listing, current_user, view_context).render
        }) }
      end
    end

    def save_price_alert
      # don't fail if the price alert can't be saved for some reason
     self.class.with_error_handling("Save price alert") do
       if params[:price_alert].present? && params[:price_alert] != PriceAlert::Discounts::NONE.to_s
         current_user.save_price_alert!(@listing, threshold: params[:price_alert])
        else
          current_user.delete_price_alert(@listing)
        end
      end
    end

    def leave_listing_comment
      if params[:comment].present?
        @listing.comment(current_user, {text: params[:comment]}, source: :save_modal)
      end
    end
end
