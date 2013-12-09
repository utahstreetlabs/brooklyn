class TrackingController < ApplicationController
  skip_requiring_login_only
  skip_store_login_redirect

  def show
    track_usage(params[:event]) if params[:event]
    render_tracking_pixel
  end

  private

  # thanks, http://forrst.com/posts/Render_a_1x1_Transparent_GIF_with_Rails-eV4
  def render_tracking_pixel
    send_data(Base64.decode64("R0lGODlhAQABAPAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="), :type => "image/gif", :disposition => "inline")
  end
end
