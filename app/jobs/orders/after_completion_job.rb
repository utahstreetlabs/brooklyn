require 'grant_inviter_credits'
require 'orders/job_base'

module Orders
  class AfterCompletionJob < JobBase
    @queue = :orders

    def self.work(id)
      with_error_handling("After completion of order #{id}") do
        order = Order.find(id)
        notify_buyer_order_completed(order)
        email_buyer_order_completed(order)
        notify_seller_order_completed(order)
        email_seller_order_completed(order)
        grant_inviter_credits(order)
        send_seller_hook(order)
        update_mixpanel(order)
        track_order_completion(order)
      end
    end

    def self.notify_buyer_order_completed(order)
      inject_notification(:OrderCompleted, order.buyer_id, order_id: order.id)
    end

    def self.email_buyer_order_completed(order)
      send_email(:completed_for_buyer, order)
    end

    def self.notify_seller_order_completed(order)
      inject_notification(:OrderCompleted, order.listing.seller_id, order_id: order.id)
    end

    def self.email_seller_order_completed(order)
      send_email(:completed_for_seller, order)
    end

    def self.grant_inviter_credits(order)
      buyer = order.buyer
      completed_order_count = buyer.completed_bought_orders.count
      if (completed_order_count == 1)
        logger.info("Queueing job to grant inviter credits for #{buyer.id}")
        GrantInviterCredits.enqueue(buyer.id)
      else
        logger.info("Not granting inviter credits for #{buyer.id} because completed order count is #{completed_order_count}")
      end
    end

    def self.track_order_completion(order)
      track_usage(:complete_purchase, user: order.buyer)
      track_usage(:complete_sale, user: order.listing.seller)
    end

    def self.update_mixpanel(order)
      order.buyer.mark_buyer!
      order.buyer.mixpanel_increment!(purchases: 1, purchase_dollars: order.listing.subtotal,
        credits_used: order.credit_amount)
      order.buyer.mixpanel_sync!(buyer_properties(order))
      order.listing.seller.mark_seller!
      order.listing.seller.mixpanel_increment!(sales: 1, sales_dollars: order.listing.subtotal)
      order.listing.seller.mixpanel_sync!(seller_properties(order))
    end

    def self.buyer_properties(order)
      p = {}
      p[:first_purchased_at] = Time.zone.now if order.buyer.completed_bought_orders_count == 1
      p
    end

    def self.seller_properties(order)
      p = {}
      p[:first_sold_at] = Time.zone.now if order.listing.seller.completed_sold_orders_count == 1
      p
    end
  end
end
