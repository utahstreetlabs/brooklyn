require 'ladon'

module Facebook
  class OpenGraphJob < Ladon::Job
    include Brooklyn::Sprayer
    include OpenGraph
    include Stats::Trackable

    acts_as_unique_job

    def self.track_action(user, type, action, &block)
      track_usage(:open_graph_action, user: user, type: type, action: action, &block)
    end

    def self.fb_ref_user_data(actor)
      {
        user_slug: actor.slug, created_at: Time.zone.now.to_s
      }
    end
  end
end
