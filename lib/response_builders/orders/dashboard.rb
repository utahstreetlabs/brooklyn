module ResponseBuilders
  module Orders
    class Dashboard < ::ResponseBuilders::Orders::Base
      def build_success(initial_data = {})
        data = initial_data.dup
        data[:listingId] = order.listing.id
        data[:overlay] = render_order_overlay
        data[:listing] = render_listing
        data
      end

      def render_order_overlay
        action = case order.status.to_sym
        when :confirmed then :ship
        else nil
        end
        if action
          renderer.render_to_string(:partial => "/dashboard/#{user_role}_#{action}.html", :locals => {:order => order})
        else
          ''
        end
      end

      def render_listing
        prefix = user_role == :seller ? :sold : :bought
        renderer.render_to_string(:partial => "/dashboard/#{prefix}_listing.html",
          :locals => {:listing => order.listing})
      end
    end
  end
end
