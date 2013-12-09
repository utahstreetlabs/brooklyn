class RootController < ApplicationController
  include Controllers::LandingPageScoped

  def show
    render_landing_page('root')
  end
end
