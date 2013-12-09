require 'resque'
require 'ladon'

class TrackUsage < Ladon::Job
  include Brooklyn::MixpanelContext
  include Ladon::ErrorHandling

  @queue = :tracking

  def self.work(event, params = {})
    name = event_name(event)
    with_error_handling("Track event #{name} with params #{params}", params.merge(name: name)) do
      params = self.mixpanel_context.merge(params)
      # delete user_id even if we don't need it, so we don't send to mixpanel
      user_id = params.delete(:user_id)
      user = User.find(user_id) if user_id
      params.merge!(user.mixpanel_properties) if user
      Brooklyn::Mixpanel.track(name, complete_event_properties(event, params))
    end
  end

  # Return the name of this event. Uses the string defined
  # in the event class if passed a class name, otherwise
  # returns the given string.
  #
  # @param event [String] The name of the event to return
  def self.event_name(event)
    begin
      event.constantize.event_name
    rescue NameError
      event
    end
  end

  # Use the "complete_properties" method in the event
  # to load additional properties to pass with this event.
  #
  # @param event [String] The name of the event to return
  def self.complete_event_properties(event, props)
    begin
      event.constantize.complete_properties(props)
    rescue NameError
      props
    end
  end
end
