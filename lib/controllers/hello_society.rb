module Controllers

  # Hello Society is a marketing tool we are using to drive pinterest activity.
  # They have a team of high profile pinners who will refer traffic our way. When
  # we get traffic from them, we need to remember that and let them know if the
  # user they referred signs up. We take note in the current session and then
  # queue a job to notify them at registration. We also take note of the campaign
  # they were referred by in mixpanel so we can verify things on our side.
  module HelloSociety
    extend ActiveSupport::Concern

    included do
      before_filter do
        remember_hello_society_campaign if request_referred_by_hello_society?
      end
    end

    def request_referred_by_hello_society?
      params[:source] == 'Pinterest' && params[:medium] == 'HardPin' && params[:campaign]
    end

    def remember_hello_society_campaign
      session[:hello_society_campaign] = params[:campaign]
    end

    def clear_hello_society_campaign
      session[:hello_society_campaign] = nil
    end

    def hello_society_campaign
      session[:hello_society_campaign]
    end

    def hello_society_referral?
      !!hello_society_campaign
    end

    def notify_hello_society_of_signup(campaign)
      NotifyHelloSociety.enqueue(campaign) if feature_enabled? :client, :hello_society_tracking
    end
  end
end
