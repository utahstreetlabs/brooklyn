module Controllers
  # Provides common behaviors for controllers/views that include the invite your friends module
  module InviteYourFriends
    extend ActiveSupport::Concern

    included do
      helper_method :find_pileon, :inviter_profiles
    end

    module InstanceMethods
    protected
      def load_invite_suggestions
        @invite_suggestions = current_user.person.invite_suggestions
        if @invite_suggestions and @invite_suggestions.any?
          fire_event(:invite_display_suggestion, user: current_user, invitee_ids: @invite_suggestions.map(&:id),
            network: @invite_suggestions[0].network)
        end
        # Give pileons preference and drop them at the top
        @pileon_suggestion = find_pileon(@invite_suggestions)
        if @pileon_suggestion
          @invite_suggestions.delete(@pileon_suggestion)
          @invite_suggestions = [@pileon_suggestion] + @invite_suggestions
        end
        @invite_suggestions
      end

      def find_pileon(suggestions)
        suggestions.find {|s| inviter_profiles(s).any? }
      end

      def inviter_profiles(suggestion)
        unless defined?(@inviter_profiles)
          profile = current_user.person.for_network(suggestion.network)
          @inviter_profiles = profile ? suggestion.inviters_following(profile) : []
        end
        @inviter_profiles
      end
    end

    module ClassMethods
      def load_invite_suggestions(options = {})
        before_filter(options) { load_invite_suggestions }
      end
    end
  end
end
