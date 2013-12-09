require 'active_support/notifications'
require 'multi_json'
require 'syslog'

module Brooklyn
  # Handles application events by writing them out to an event log. Application events are fired by Active Support and
  # are represented as instances of +ActiveSupport::Notifications::Event+. A notification event has a name, duration and
  # payload. We merge the name and duration into the payload, encode the payload as a JSON string, and write it to
  # syslog.
  #
  # The event log understands two types of application events:
  #
  # 1. Controller events, which are fired after a controller's action method returns a response. A controller event's
  #    name is a composite of the controller and action name (e.g. "ListingsController#show"), and its duration is the
  #    total time taken to process the request and return a response.
  # 2. Custom events, which are fired explicitly by application code. The name and duration of a custom event are as
  #    defined by the firing application code.
  #
  # The payload is subject to a value expansion process based on its contents. For each of the expansions defined in
  # the +EXPANSIONS+ hash, if the payload contains an entry with the same key as the expansion key, then for each
  # expansion value, the corresponding method is called on the payload value, and the return value is added to the
  # payload under the method name. After expansion, the original payload entry is removed. Example: if the payload
  # contains a +user+ entry whose value is a +User+ object, the +id+ and +name+ methods are called on the +User+, and
  # the return values are added to the payload under the names +user_id+ and +user_name+.
  #
  # Also, if the payload contains a +request+ entry, the request headers named by the +HEADERS+ array are added to the
  # payload. The request itself is removed from the payload.
  class EventLog
    EXPANSIONS = {user: [:id, :name], category: [:id], request: [:remote_ip], listing: [:id, :slug, :seller_id],
      profile_user: [:id], order: [:id]}
    HEADERS = ['HTTP_REFERER', 'HTTP_USER_AGENT']

    cattr_accessor :logger
    @@logger =  nil

    def self.log_controller_event(event)
      payload = event.payload.merge(duration: event.duration).reject {|k, v| k == :params}
      payload[:event] = "#{payload.delete(:controller)}##{payload.delete(:action)}"
      write_payload(payload)
    end

    def self.log_custom_event(event)
      payload = event.payload.merge(duration: event.duration, event: event.name)
      write_payload(payload)
    end

    def self.embellish_payload(payload)
      if payload[:request].present?
        headers = payload[:request].headers
        HEADERS.each { |h| payload["request_#{h.downcase}".to_sym] = headers[h] if headers.key?(h) }
        payload[:session_id] = payload[:request].session_options[:id]
      end
      EXPANSIONS.each do |type,fields|
        object = payload.delete(type)
        if object
          fields.each { |f| payload["#{type}_#{f}".to_sym] = object.send(f) if object.respond_to?(f) }
        end
      end
      payload
    end

    def self.write_payload(payload)
      logger.log(Syslog::LOG_INFO, MultiJson.encode(embellish_payload(payload)))
    end

    # Initializes handlers for notifications that should result in log entries.
    def self.setup
      # Log a controller event for every +process_action+ event emitted by the controller.
      ActiveSupport::Notifications.subscribe /process_action.action_controller/ do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        Brooklyn::EventLog.log_controller_event(event) unless event.payload[:skip] == true
      end

      # Log a custom event for every +custom_event+ event emitted by the application.
      ActiveSupport::Notifications.subscribe /.brooklyn/ do |*args|
        Brooklyn::EventLog.log_custom_event(ActiveSupport::Notifications::Event.new(*args))
      end
    end
  end
end
