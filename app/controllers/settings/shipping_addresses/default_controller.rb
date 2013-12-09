class Settings::ShippingAddresses::DefaultController < ApplicationController
  set_flash_scope 'settings.shipping'

  def update
    @address = current_user.postal_addresses.find(params[:shipping_address_id].to_i)
    @address.default!
    set_flash_message(:notice, :default_updated)
    redirect_to(settings_shipping_addresses_path)
  end
end
