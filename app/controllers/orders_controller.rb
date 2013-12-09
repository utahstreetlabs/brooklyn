class OrdersController < ApplicationController
  include Controllers::OrderScoped

  respond_to :json

  set_and_require_order except: [:settle]
  require_seller :only => :ship
  require_buyer :only => :complete

  customize_action_event variables: [:order]

  before_filter except: [:settle] do
    @response_builder = ResponseBuilders::Orders.create(params[:source], current_user, @order, self)
  end

  def ship
    if @order.can_ship?
      @order.build_shipment(shipment_params) unless @order.shipment
      @order.shipment.attributes = shipment_params
      if @order.ship
        data = {:message => localized_flash_message(:shipped),
          :listing => render_to_string(partial: '/dashboard/sold_listing.html', locals: {listing: @order.listing })}
        render_jsend(:success => @response_builder.build_success(data))
      else
        logger.warn("Unable to ship order %s: shipment had errors %s" %
          [@order.id, @order.shipment.errors.full_messages.join("; ")])
          render_jsend(:fail => @response_builder.build_failure(message: I18n.t("controllers.orders.invalid_shipment")))
       end
    else
      render_jsend(error: localized_flash_message(:already_shipped))
    end
  end

  def complete
    if @order.can_complete?
      @order.complete_and_attempt_to_settle!
    end
    data = {:message => localized_flash_message(:completed)}
    render_jsend(:success => @response_builder.build_success(data))
  end

  def public
    @order.make_public
    data = {message: localized_flash_message(:public)}
    render_jsend(success: @response_builder.build_success(data))
  end

  def private
    @order.make_private
    data = {message: localized_flash_message(:private)}
    render_jsend(success: @response_builder.build_success(data))
  end

  def settle
    begin
      current_user.settle_all_complete_orders!
      if current_user.default_deposit_to_paypal?
        set_flash_message(:notice, :settle_paypal)
      else
        set_flash_message(:notice, :settle_bank_account)
      end
    rescue Order::IncompleteSettlement => e
      logger.error("Error releasing funds for user #{current_user.id}: #{e}")
      set_flash_message(:alert, :error_settling,
        help_link: view_context.mail_to(Brooklyn::Application.config.email.to.help))
    end
    redirect_to(:back)
  end

  protected
    def shipment_params
      params[:shipment].slice(:carrier_name, :tracking_number)
    end
end
