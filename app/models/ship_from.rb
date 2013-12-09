class ShipFrom < ShipBase
  def self.create(listing, master_addresses)
    attrs = {master_addresses: master_addresses}
    if master_addresses.any?
      if listing.return_address
        selected_address = master_addresses.detect {|a| a.equivalent?(listing.return_address)}
        attrs[:address_id] = selected_address.id if selected_address
      end
      attrs[:address_id] ||= master_addresses.first.id
    end
    new(attrs)
  end
end
