module Controllers
  # Provides common behaviors for controllers that are scoped to the dashboard.
  module DashboardScoped
    extend ActiveSupport::Concern

    included do
      helper_method :show_right_sidebar?, :suppress_right_sidebar
    end

    module InstanceMethods
      extend ActiveSupport::Memoizable

      def suppress_right_sidebar
        @suppress_right_sidebar = true
      end

      def show_right_sidebar?
        not @suppress_right_sidebar
      end
    end

    module ClassMethods
      def load_sidebar(options = {})
        before_filter(options) do
          @listing_counts = Listing.count_sold_by(current_user).inject({}) do |memo, kv|
            memo.update({kv[0].to_sym => kv[1]})
          end
          @listing_counts[:bought] = Listing.count_bought_by(current_user)
        end
      end
    end
  end
end
