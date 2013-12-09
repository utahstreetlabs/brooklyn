module Events
  class FbNotificationSent < Base
    set_event_name 'fb_notification sent'

    def initialize(properties = {})
      @properties = properties
    end

    def self.complete_properties(props)
      props
    end
  end
end
