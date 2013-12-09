class ShipTo < ShipBase
  attr_accessor :bill_to_shipping

  def bill_to_shipping?
    !!bill_to_shipping
  end

  def self.create(order, master_addresses)
    attrs = {master_addresses: master_addresses, bill_to_shipping: order.bill_to_shipping}
    if master_addresses.any?
      if order.shipping_address
        selected_address = master_addresses.detect {|a| a.equivalent?(order.shipping_address)}
        attrs[:address_id] = selected_address.id if selected_address
      end
      attrs[:address_id] ||= master_addresses.first.id
    end
    new(attrs)
  end
end
