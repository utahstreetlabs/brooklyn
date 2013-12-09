class Listings::ModalController < ApplicationController
  include Controllers::ListingScoped

  skip_requiring_login_only
  set_listing
  respond_to :json

  def show
    collections = current_user.nil? ? nil : current_user.collections
    track_usage(Events::ListingModalView.new(@listing))
    render_jsend(success: {
      modal: Listings::ModalExhibit.new(@listing, current_user, view_context).render,
      saveManager: Listings::SaveManagerExhibit.new(@listing, current_user, view_context,
        collections: collections, source: 'listing_modal').render
    })
  end
end
