class Admin::Users::OrdersController < ApplicationController
  layout 'admin'

  load_and_authorize_resource :user

  def index
    authorize! :index, Order
    @orders = Order.where(buyer_id: params[:user_id])
    @orders = @orders.datagrid(params, includes: [:buyer, {listing: :seller}])
  end

  def show
    begin
      @order = Order.find(params[:id])
      @order.build_shipment(carrier_name: Brooklyn::Carrier.available.first.key) unless @order.shipment
    rescue ActiveRecord::RecordNotFound
      @order = CancelledOrder.find(params[:id])
    end
    authorize! :index, @order
  end
end
