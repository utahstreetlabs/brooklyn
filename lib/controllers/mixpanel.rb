module Controllers
  # A controller concern that adds a before filter that will automatically
  # gather a variety of information from the current request and store it
  # using into the "mixpanel context" so that other components can access it
  # when making tracking calls from, eg, models.
  module Mixpanel
    extend ActiveSupport::Concern

    included do
      include Ladon::ErrorHandling
      include Brooklyn::MixpanelContext
      helper_method :mixpanel_superproperty_js, :forget_mp_superproperties, :browse_page_source

      after_filter do
        self.class.with_error_handling 'clearing mixpanel context' do
          self.class.mixpanel_context = {}
        end
      end
    end

    protected

    def mp_first_touch
      session[:mp_first_touch] ||= {}
    end

    def mp_last_touch
      session[:mp_last_touch] ||= {}
    end

    # Remember superproperties in the session so we can use the mixpanel
    # javascript library to set them the first time we load the javascript
    #
    # This is necessary because we sometimes send users to URLs (like the
    # listing creation url) that redirect to a new page, and some browsers
    # don't preserve query parameters across redirects
    def remember_mp_superproperties
      # awkward hash assignment syntax because we need to actually re-assign the
      # session key's value, cause sessions aren't really in memory maps
      [:utm_campaign, :utm_medium, :utm_source, :utm_term, :utm_content].each do |p|
        session[:mp_last_touch] = mp_last_touch.merge(p => params[p]) if params[p]
        session[:mp_first_touch] = mp_first_touch.merge(:"initial_#{p}" => (mp_last_touch[p] || 'None'))
      end
      session[:mp_last_touch] = mp_last_touch.merge(fb_ref: params[:fb_ref]) if params[:fb_ref]
    end

    def forget_mp_superproperties
      session[:mp_first_touch] = {}
      session[:mp_last_touch] = {}
    end

    def mixpanel_superproperty_js
      "mixpanel.register_once(#{mp_first_touch.to_json}); mixpanel.register(#{mp_last_touch.to_json});\n"
    end

    # basic information that should be passed with every event
    # visitor_id will be used to identify the user
    # mixpanel_cookies will be used to get superproperties
    # user_id will be used to pass standard user data with each event
    def mixpanel_request_context
      if user_agent_is_a_bot?
        {skip_tracking: true}
      else
        properties = {
          visitor_id: visitor_identity, ip: request.remote_ip,
          mp_cookies: mixpanel_cookies, user_id: (current_user && current_user.id),
          referrer: request.referer, user_agent: request.user_agent,
          utm_query_params: utm_query_params
        }
        properties[:fb_ref] = params[:fb_ref] if params[:fb_ref]
        properties[:source] = params[:source] if params[:source]
        properties[:page_source] = params[:page_source] if params[:page_source]
        properties
      end
    end

    BOT_REGEX = /(bot|spider|NewRelicPinger)/
    def user_agent_is_a_bot?
      request.user_agent.blank? || !!(request.user_agent =~ BOT_REGEX)
    end

    def utm_query_params
      params.slice(:utm_campaign, :utm_source, :utm_medium, :utm_term, :utm_content)
    end

    # pull out any cookies with "mixpanel" in the name so we can extract super properties based on visitor id
    def mixpanel_cookies
      request.cookies.to_a.select {|k, v| k =~ /mixpanel/}
    end

    def utmz_cookie
      request.cookies['__utmz']
    end

    def browse_page_source
      params[:search] ? :search : :browse
    end

    module ClassMethods
      def set_mixpanel_context
        before_filter do
          self.class.with_error_handling 'setting mixpanel context' do
            self.class.mixpanel_context = mixpanel_request_context
          end
        end
      end

      def skip_tracking
        before_filter do
          self.class.mixpanel_context = {skip_tracking: true}
        end
      end

      def remember_mixpanel_superproperties
        before_filter do
          remember_mp_superproperties
        end
      end
    end
  end
end
