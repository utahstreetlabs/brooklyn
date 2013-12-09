module Signup
  module Buyer
    class FollowSuggestionsExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithHelper
      set_helper :signup_buyer_follow_suggestions
      attr_reader :invite_suggestions

      def initialize(follow_suggestions, invite_suggestions, viewer, context)
        follow_suggestions = follow_suggestions || {}
        super(follow_suggestions, viewer, context)
        @invite_suggestions = invite_suggestions || []
      end

      def args
        [self, viewer, invite_suggestions: invite_suggestions]
      end
    end
  end
end
