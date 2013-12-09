class Listings::OffersController < ApplicationController
  include Controllers::ListingScoped

  set_flash_scope 'listings.offers'
  set_listing

  def create
    offer = @listing.offers.build(offer_params)
    offer.user = current_user
    if offer.save
      render_jsend(success: {
        followupModal: Listings::OfferMadeExhibit.new(@listing, offer, current_user, view_context).render,
        replace: Listings::MakeAnOfferExhibit.new(@listing, offer, current_user, view_context).render
      })
    else
      render_jsend(fail: {
        modal: Listings::OfferFailedExhibit.new(@listing, offer, current_user, view_context).render
      })
    end
  end

  protected
    def offer_params
      params[:offer] && params[:offer].slice(:amount, :duration, :message)
    end
end
