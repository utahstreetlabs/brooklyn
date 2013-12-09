class ApiController < ActionController::Base
  include Brooklyn::Urls
  include Controllers::Instrumentation
  include Controllers::TokenAuthable
  include Controllers::Mixpanel

  skip_tracking
  skip_filter :verify_authenticity_token
  session :off
  authenticate_token realm: 'Copious API'
  around_filter :catch_exceptions
  respond_to :xml, :json

protected
  # XXX: shouldn't this be using Ladon::ErrorHandling to log and notify airbrake?
  def respond_to_exception(status, options = {})
    if e = options[:exception]
      logger.error("API request error (#{e.class}): #{e}")
      e.backtrace.each { |l| logger.error(l) }
    end
    message = options[:message]
    invalid_fields = options[:invalid_fields]
    if message || invalid_fields
      render template: 'api/error', locals: {error_message: message, invalid_fields: invalid_fields}, status: status
    else
      render nothing: true, status: status
    end
  end

  def catch_exceptions
    begin
      yield
    rescue ActiveRecord::RecordInvalid => e
      respond_to_exception(400, invalid_fields: e.record.errors)
    rescue StateMachine::InvalidTransition => e
      if e.object.errors.values.flatten.any? {|v| v !~ /cannot transition/i }
        respond_to_exception(400, invalid_fields: e.object.errors)
      else
        # XXX: should be 409
        respond_to_exception(400, message: "Invalid state transition")
      end
    rescue ActiveRecord::RecordNotFound => e
      respond_to_exception(404)
    rescue ActiveRecord::RecordNotUnique => e
      # XXX: should be 409
      respond_to_exception(400, message: 'Not created: Already exists')
    rescue Exception => e
      respond_to_exception(500, message: 'An unexpected error occurred.', exception: e)
    end
  end

  def current_user
    @user
  end
end
