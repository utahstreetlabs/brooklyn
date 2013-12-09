module Admin
  module OrdersHelper
    def admin_order_complete_button(order)
      options = {
        method: :post,
        condition: :primary,
        icon: :forward,
        inverted_icon: true,
        data: {action: :complete}
      }
      if order.settleable?
        text = t('.complete.button.complete_and_settle')
      else
        options[:title] = if order.seller_has_merchant_account?
          t('.complete.tooltip.no_default_deposit_account')
        else
          t('.complete.tooltip.no_merchant_account')
        end
        options[:rel] = :tooltip
        text = t('.complete.button.complete')
      end
      bootstrap_button(text, complete_admin_order_path(order.id), options)
    end

    def admin_order_settle_button(order)
      options = {
        method: :post,
        condition: :primary,
        icon: :forward,
        inverted_icon: true,
        data: {action: :settle}
      }
      if order.settleable?
        path = settle_admin_order_path(order.id)
      else
        options[:title] = if order.seller_has_merchant_account?
          t('.settle.tooltip.no_default_deposit_account')
        else
          t('.settle.tooltip.no_merchant_account')
        end
        options[:rel] = :tooltip
        options[:disabled] = true
        path = nilhref
      end
      bootstrap_button(t('.settle.button'), path, options)
    end
  end
end
