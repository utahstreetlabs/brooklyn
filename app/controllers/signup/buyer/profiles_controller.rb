module Signup
  module Buyer
    class ProfilesController < ApplicationController
      include Controllers::Onboarding
      layout 'signup/buyer'

      skip_requiring_login_only
      skip_store_login_redirect
      before_filter :require_connection_only

      def new
        current_user.slugify
        current_user.email = nil if Rubicon::FacebookProfile.anonymous_email?(current_user.email)
        @profile = current_user.person.network_profiles.values.first
      end

      def create
        respond_to do |format|
          remember_signup_flow_destination
          current_user.attributes = params[:user]
          current_user.validate_completely!
          current_user.guest_to_absorb = guest_user
          set_visitor_id(current_user)
          if feature_enabled?(:signup, :recaptcha) && current_user.person.for_network(:twitter).present?
            verified = verify_recaptcha(current_user)
          else
            verified = true
          end

          if verified && current_user.register
            track_create_profile
            clear_visitor_id_cookie
            sign_in(current_user)
            remove_guest
            publish_signup if params[:publish] == '1'
            request_display(:registration_trackers)
            self.signup_just_registered = true
            if feature_enabled?('onboarding.follow_friends_modal') && current_user.connected_to?(:facebook)
              set_show_follow_friends
            end
            format.html { redirect_after_profile }
            format.json { render_jsend(success: {}) }
          else
            unless verified
              flash.delete(:recaptcha_error)
              set_flash_message(:alert, :invalid_captcha)
            end
            current_user.slugify if current_user.slug.blank?
            format.html { render(:new) }
            format.json { render_jsend(fail: {errors: current_user.errors}) }
          end
        end
      end

      protected

      def redirect_after_profile
        if feature_enabled?('onboarding.skip_interests')
          redirect_after_interests
        else
          redirect_to(signup_buyer_interests_path)
        end
      end

      def track_create_profile
        self.class.with_error_handling 'tracking onboarding create profile' do
          props = {network: current_user.person.connected_networks.first}
          props[:hello_society_campaign] = hello_society_campaign if hello_society_referral?
          # technically the same thing now, might be different in the future
          track_usage(:onboarding_create_profile, props)
          track_usage(:registration_complete, props)
        end
        self.class.with_error_handling 'letting hello society know about signup' do
          notify_hello_society_of_signup(hello_society_campaign) if hello_society_referral?
          clear_hello_society_campaign
        end
      end

      def publish_signup
        # XXX: we should update this to be more explicit - the view should tell us which network
        #      the user authorized, and we should only publish to that network
        begin
          current_user.publish_signup!
        rescue Exception => e
          # fail silently but notify airbrake - we don't want this to block forward progress
          notify_airbrake(e)
        end
      end
    end
  end
end
