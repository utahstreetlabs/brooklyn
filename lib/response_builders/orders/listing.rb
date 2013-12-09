module ResponseBuilders
  module Orders
    class Listing < ::ResponseBuilders::Orders::Base
      def build_success(initial_data = {})
        data = initial_data.dup
        data[:orderInfo] = render_order_info
        data
      end

      def render_order_info
        renderer.render_to_string(:partial => "/listings/#{user_role}_#{order.status}.html",
          :locals => {:listing => order.listing})
      end
    end
  end
end
