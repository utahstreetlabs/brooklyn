module Controllers
  # Provides common behaviors for controllers that are scoped to a user's network profile
  module NetworkProfileScoped
    extend ActiveSupport::Concern

    module ClassMethods
      def load_profile(options = {})
        before_filter(options) { load_profile }
      end
    end

    module InstanceMethods
      protected

      def load_profile
        @profile = Profile.find(params[:id])
        respond_not_found unless @profile
      end
    end
  end
end
