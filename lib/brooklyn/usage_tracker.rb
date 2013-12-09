module Brooklyn
  class UsageTracker
    class << self
      attr_accessor :driver
      delegate :async_track, :async_set, :async_increment, to: :driver
    end
  end

  class TestUsageTracker
    def async_track(event, params = {})
    end

    def async_set(user, params = {})
    end

    def async_increment(user, params = {})
    end
  end

  class LiveUsageTracker
    def async_track(event, params = {})
      if event.is_a?(Events::Base)
        event_name = event.class.name
        params.merge!(event.properties)
      elsif event.is_a?(Symbol)
        config = Brooklyn::Application.config.tracking.events
        # use a sensible default if the event is not defined in app_config.yml
        event_name = config.respond_to?(event) ? config.send(event) : event.to_s.gsub('_', ' ')
      else
        event_name = event
      end
      params[:user_id] = params.delete(:user).id if params[:user]
      # get the time now, before the delay of the queuing is introduced
      # set "timestamp" too, to allow segmentation on action time
      params[:time] = params[:timestamp] = Time.zone.now.to_i
      TrackUsage.enqueue(event_name, params)
    end

    def async_set(user, params = {})
      ::Mixpanel::SetProperties.enqueue(user.id, params)
    end

    def async_increment(user, params = {})
      ::Mixpanel::IncrementProperties.enqueue(user.id, params)
    end
  end
end
