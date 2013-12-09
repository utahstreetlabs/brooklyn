class Listings::Modal::LikeController < ApplicationController
  include Controllers::ListingScoped

  set_listing
  respond_to :json

  def update
    current_user.like(@listing)
    render_jsend(success: Listings::Modal::CtasExhibit.new(@listing, current_user, view_context).render)
  end

  def destroy
    current_user.unlike(@listing)
    render_jsend(success: Listings::Modal::CtasExhibit.new(@listing, current_user, view_context).render)
  end
end
