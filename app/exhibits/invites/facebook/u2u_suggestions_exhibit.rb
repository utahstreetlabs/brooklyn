module Invites
  module Facebook
    class U2uSuggestionsExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithHelper
      set_helper :invite_modal_invite_suggestions

      def args
        [self, viewer, options]
      end
    end
  end
end
