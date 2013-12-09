class Api::Orders::ShipmentsController < ApiController
  respond_to :xml, :json

  before_filter only: [:index, :create] do
    @order = Order.find_by_reference_number!(params[:order_id])
    # XXX: require that the current token's user is the seller
  end

  # XXX: why is this a collection resource controller? an order can only have one shipment
  def index
    @shipment = Shipment.find_by_order_id!(@order.id)
    @listing = Listing.find(@order.listing_id)
    respond_with @order
  end

  def create
    @order.build_shipment(shipment_params)
    @order.ship!
    respond_with('', status: 201, location: api_order_url(@order))
  end

  protected
    def shipment_params
      p = params[:shipment] || {carrier: ''}
      {carrier_name: p[:carrier].downcase, tracking_number: p[:tracking_number] }
    end
end
