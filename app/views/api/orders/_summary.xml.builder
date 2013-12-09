xml.order do
  xml.reference order.reference_number
  xml.status order.status
  xml.listing do
    xml.slug listing.slug
    xml.source_uid listing.source_uid
    xml.link 'href' => api_listing_url(listing)
    xml.link "rel" => "alternate", "href" => listing_url(listing)
    xml.price listing.price
    xml.shipping listing.shipping
  end
  xml.buyer do
    xml.name listing.buyer.name
    xml.email listing.buyer.email
    xml.uuid listing.buyer.uuid
    [:line1, :line2, :city, :state, :zip, :phone].each do |key|
      xml.send(key, order.shipping_address.send(key)) if order.shipping_address.send(key).present?
    end
  end
  xml.discount 0.00
  xml.proceeds listing.proceeds
  xml.payment_type order.payment_type
  xml.order_time order.created_at.to_time.to_i
  xml.link 'href' => api_order_url(order.reference_number)
end
