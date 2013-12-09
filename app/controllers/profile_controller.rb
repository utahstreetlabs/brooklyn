require 'rubicon/models/facebook_profile'

class ProfileController < ApplicationController
  include Brooklyn::Observable

  skip_requiring_login_only

  before_filter :require_connection_only
  before_filter :store_redirect, only: :new
  before_filter { @user = current_user }

  def new
    @user.slugify
    @user.email = nil if Rubicon::FacebookProfile.anonymous_email?(@user.email)
    @profile = @user.person.network_profiles.values.first
  end

  def create
    @user.attributes = params[:user]
    @user.validate_completely!
    @user.guest_to_absorb = guest_user
    set_visitor_id(@user)
    if feature_enabled?(:signup, :recaptcha) && @user.person.for_network(:twitter).present?
      verified = verify_recaptcha(@user)
    else
      verified = true
    end
    if verified && @user.register
      clear_visitor_id_cookie
      sign_in(@user)
      remove_guest
      publish_signup if params[:publish] == '1'
      track!(:registrations)
      request_display(:registration_trackers)
      redirect_after_register
    else
      unless verified
        flash.delete(:recaptcha_error)
        set_flash_message(:alert, :invalid_captcha)
      end
      current_user.slugify if current_user.slug.blank?
      render(:new)
    end
  end

  protected
    def publish_signup
      # XXX: we should update this to be more explicit - the view should tell us which network
      #      the user authorized, and we should only publish to that network
      begin
        @user.publish_signup!
      rescue Exception => e
        # fail silently but notify airbrake - we don't want this to block forward progress
        notify_airbrake(e)
      end
    end
end

