xml.instruct!

xml.shipment do
  xml.order do
    xml.reference @listing.order.reference_number
    xml.link 'href' => api_order_url(@shipment.order.reference_number)
  end
  xml.carrier @shipment.carrier_name
  xml.tracking_number @shipment.tracking_number
  xml.shipping_time @shipment.created_at.to_time.to_i if @shipment.created_at
  xml.delivery_time @shipment.delivered_at.to_time.to_i if @shipment.delivered_at
end
