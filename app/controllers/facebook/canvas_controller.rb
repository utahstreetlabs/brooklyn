class Facebook::CanvasController < ApplicationController
  skip_requiring_login_only
  skip_enable_autologin
  skip_store_login_redirect
  protect_from_forgery except: :show

  def show
    # track whatever params FB sends us
    properties = params.dup
    properties[:user] = current_user if logged_in?
    track_usage('facebook_canvas_page view', properties)
    render(text: view_context.javascript_tag("top.location.href='#{oauth_url}'"))
  end

  # Returns the url for fb canvas login dialog with the redirect uri set to the /auth/facebook endpoint
  # https://developers.facebook.com/docs/howtos/login/login-for-canvas
  def oauth_url
    url = <<-URL
      https://www.facebook.com/dialog/oauth/
      ?client_id=#{Network::Facebook.app_id}
      &redirect_uri=#{URI.escape("#{root_url}auth/facebook/?r=#{redirect_for(request.referer)}")}
      &scope=#{Network::Facebook.scope}
    URL
    url.gsub(/\s+/, '')
  end

  def redirect_for(referer)
    options = {secure: true}
    # src is used to determine the Copious action or entity that generated the FB notification (eg a price alert)
    options[:src] = params[:src] if params[:src].present?
    redirect = nil
    if referer =~ /#{Brooklyn::Application.config.networks.facebook.notification.canvas_redirect_regex}/
      h = Rails.application.routes.recognize_path($1)
      redirect = case h[:controller].to_sym
        when :listings
          listing_url(h[:id], options)
        when :profiles
          public_profile_url(h[:id], options)
      end
    end
    redirect || root_url(options)
  end
end
