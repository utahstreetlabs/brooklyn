class Dashboard::OrdersController < ApplicationController
  include Controllers::OrderScoped

  respond_to :json
  set_and_require_order
  require_buyer

  def private
    @order.make_private
    render_jsend(:success)
  end

  def public
    @order.make_public
    render_jsend(:success)
  end

  def delivered
    @order.deliver! if @order.can_deliver?
    next_step_exhibit = Dashboard::Buyer::DeliveryConfirmedExhibit.new(@order, current_user, view_context)
    listing_exhibit = Dashboard::Buyer::ListingExhibit.new(@order.listing, current_user, view_context)
    render_jsend(success: {modal: next_step_exhibit.render, listingId: @order.listing_id,
                           listing: listing_exhibit.render})
  end

  def not_delivered
    @order.report_non_delivery!
    # no need to replace the listing since the order's state hasn't changed
    next_step_exhibit = Dashboard::Buyer::DeliveryNotConfirmedExhibit.new(@order, current_user, view_context)
    render_jsend(success: {modal: next_step_exhibit.render})
  end
end
