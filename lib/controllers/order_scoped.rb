module Controllers
  # Provides common behaviors for controllers that are scoped to a listing.
  module OrderScoped
    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval <<-EOT
        helper_method :buyer?, :seller?
      EOT
    end

    module ClassMethods
      def set_and_require_order(options = {})
        before_filter(options) do
          id = params[:order_id] || params[:id]
          @order = Order.find(id)
          unless @order
            logger.warn("Disallowing as order #{id} not found")
            respond_unauthorized
          end
        end
      end

      def require_buyer(options = {})
        before_filter(options) do
          unless buyer?
            logger.warn("Disallowing as current user is not buyer of listing #{@order.listing.id}")
            respond_unauthorized
          end
        end
      end

      def require_seller(options = {})
        before_filter(options) do
          unless seller?
            logger.warn("Disallowing as current user is not seller of listing #{@order.listing.id}")
            respond_unauthorized
          end
        end
      end

      def require_buyer_or_seller(options = {})
        before_filter(options) do
          unless buyer? || seller?
            logger.warn("Disallowing as current user is not buyer or seller of listing #{@order.listing.id}")
            respond_unauthorized
          end
        end
      end
    end

    def buyer?
      @order.bought_by?(current_user)
    end

    def seller?
      @order.listing.sold_by?(current_user)
    end
  end
end
