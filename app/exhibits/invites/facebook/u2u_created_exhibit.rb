module Invites
  module Facebook
    class U2uCreatedExhibit < Exhibitionist::Exhibit
      include Exhibitionist::RenderedWithHelper
      set_helper :invite_bar

      def args
        [viewer, options.merge(request: self)]
      end
    end
  end
end
