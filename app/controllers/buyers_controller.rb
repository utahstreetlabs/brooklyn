class BuyersController < ApplicationController
  include Controllers::LandingPageScoped

  before_filter :require_not_logged_in

  def show
    render_landing_page('buyers')
  end
end
