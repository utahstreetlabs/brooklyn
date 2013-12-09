class Api::OrdersController < ApiController
  respond_to :xml, :json

  before_filter only: :index do
    @orders = Order.sold_by_user_with_listings(@user.id)
    [:updated_after, :updated_before].each do |key|
      @orders = @orders.send(key, Time.zone.at(params[key].to_i)) if params.has_key?(key)
    end
  end

  before_filter only: :show do
    @order = Order.find_by_reference_number!(params[:id])
  end

  def index
    respond_with @orders
  end

  def show
    respond_with @order
  end
end
