module Events
  class ProfileView < Base
    set_event_name 'profile view'

    def initialize(user, properties = {})
      @properties = {profile_user_id: user.id}.merge(properties)
    end

    def self.complete_properties(props)
      props.merge(profile_properties(props.delete(:profile_user_id)))
    end
  end
end
