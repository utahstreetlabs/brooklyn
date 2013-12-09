class SellersController < ApplicationController
  include Controllers::LandingPageScoped

  before_filter :require_not_logged_in

  def show
    # special case where two separate routes use the same template. refactor if another case occurs.
    @skip_layout = true if params[:template] == 'etsy-seller'
    params[:template] = 'closet-sellers' if params[:template] == 'closet-sellers-aw'
    render_landing_page('sellers')
  end
end
