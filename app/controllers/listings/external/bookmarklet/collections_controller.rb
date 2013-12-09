class Listings::External::Bookmarklet::CollectionsController < ApplicationController
  include Controllers::ListingScoped
  set_flash_scope 'listings.external.bookmarklet.collections'
  set_listing

  def index
    @collections = current_user.collections
    @price_alert = current_user.price_alert_for(@listing) || current_user.build_price_alert(@listing)
  end
end
