class Admin::OrdersController < ApplicationController
  layout 'admin'
  set_flash_scope 'admin.orders'
  # XXX: migrate the rest of the controller to cancan
  before_filter :require_admin, only: [:index, :cancelled, :handling_expired, :show]
  load_resource except: [:index, :cancelled, :handling_expired, :show]
  respond_to :json, only: [:ship]

  def index
    @orders = Order.datagrid(params, includes: [:buyer, {listing: [:seller, :shipping_option]}])
  end

  def cancelled
    @orders = CancelledOrder.datagrid(params, includes: [:buyer, {listing: :seller}])
  end

  def handling_expired
    @orders = Order.find_confirmed_past_handling_by(0).
      datagrid(params, includes: [:buyer, {listing: :seller}])
  end

  def show
    @order = Order.find(params[:id])
    @order.build_shipment(carrier_name: Brooklyn::Carrier.available.first.key) unless @order.shipment
  rescue ActiveRecord::RecordNotFound
    @order = CancelledOrder.find(params[:id])
  end

  def complete
    authorize!(:complete, @order)
    authorize!(:settle, @order)
    if @order.can_complete?
      @order.complete_and_attempt_to_settle!
      if @order.settled?
        set_flash_message(:notice, :completed_and_settled)
      else
        set_flash_message(:notice, :completed)
      end
    else
      set_flash_message(:alert, :error_completing)
    end
    redirect_to(admin_order_path(@order.id))
  end

  def deliver
    authorize!(:deliver, @order)
    if @order.can_deliver?
      @order.deliver!
      set_flash_message(:notice, :delivered)
    else
      set_flash_message(:alert, :error_delivering)
    end
    redirect_to(admin_order_path(@order.id))
  end

  def settle
    authorize!(:settle, @order)
    if @order.can_settle?
      @order.settle!
      set_flash_message(:notice, :settled)
    else
      set_flash_message(:alert, :error_settling)
    end
    redirect_to(admin_order_path(@order.id))
  end

  def ship
    authorize!(:ship, @order)
    if @order.can_ship?
      @order.build_shipment(shipment_params)
      if @order.ship
        render_jsend(success: {
          alert: view_context.admin_notice(:success, localized_flash_message(:shipped)),
          refresh: render_to_string(partial: 'order_info', locals: {order: @order})
        })
      else
        render_jsend(fail: {modal: render_to_string(partial: 'ship_modal', locals: {order: @order})})
      end
    else
      render_jsend(error: {message: localized_flash_message(:error_shipping)})
    end
  end

  def cancel
    authorize!(:cancel, @order)
    if @order.can_cancel?
      params[:order] ||= {}
      @order.failure_reason = params[:order][:failure_reason]
      @order.cancel!
      respond_to do |format|
        canceled_order = CancelledOrder.find(@order.id)
        format.json do
         render_jsend(success: {
            alert: view_context.admin_notice(:success, localized_flash_message(:canceled)),
            refresh: render_to_string(partial: 'order_info.html', locals: {order: canceled_order})
          })
        end
        format.all do
          set_flash_message(:notice, :canceled)
          redirect_to(admin_order_path(@order.id))
        end
      end
    else
      respond_to do |format|
        format.json do
          render_jsend(error: {message: localized_flash_message(:error_canceling)})
        end
        format.all do
          set_flash_message(:alert, :error_canceling)
          redirect_to(admin_order_path(@order.id))
        end
      end
    end
  end

  protected
    def shipment_params
      params[:shipment].slice(:carrier_name, :tracking_number)
    end
end
