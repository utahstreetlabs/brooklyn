module Users
  module Mixpanel
    def mixpanel_properties
      {visitor_id: self.visitor_id, name: self.name, email: self.email,
        created_at: self.created_at, registered_at: self.registered_at}.
        merge(self.mixpanel_demographic_properties).
        merge(self.mixpanel_experiment_properties)
    end

    def mixpanel_demographic_properties
      fetch_attributes(:gender, :location, :age, :birthday, :lister?, :seller?, :buyer?)
    end

    def mixpanel_sync_properties
      {'$first_name' => self.firstname, '$last_name' => self.lastname,
       '$email' => self.email, '$created' => self.registered_at}.
        merge(self.mixpanel_demographic_properties).
        merge(self.mixpanel_experiment_properties)
    end

    def mixpanel_experiment_properties
      Brooklyn::Application.config.tracking.experiments.each_with_object({}) do |experiment, map|
        map["#{experiment}_variant"] = variant_for_experiment(experiment).to_s
      end
    end

    def mixpanel_sync!(properties = {})
      mixpanel_set!(mixpanel_sync_properties.merge(properties))
    end

    def mixpanel_set!(properties = {})
      Brooklyn::UsageTracker.async_set(self, properties)
    end

    def mixpanel_increment!(properties)
      Brooklyn::UsageTracker.async_increment(self, properties)
    end

    protected

    def fetch_attributes(*attrs)
      attrs.each_with_object({}) do |name, m|
        m[name] = self.send(name)
      end
    end
  end
end
