class Settings::ShippingAddressesController < ApplicationController
  layout 'settings'
  set_flash_scope 'settings.shipping'

  def new
  end

  def index
  end

  def update
    address_count = current_user.postal_addresses.count
    current_user.postal_addresses_attributes = params[:user][:postal_addresses_attributes]
    update_shipping_addresses(address_count)
  end

  def create
    update
  end

  def destroy
    address_count = current_user.postal_addresses.count
    @address = current_user.postal_addresses.find(params[:id].to_i)
    current_user.postal_addresses.destroy(@address)
    update_shipping_addresses(address_count)
  end

protected
  def update_shipping_addresses(old_address_count, options = {})
    if current_user.save
      # After save, if this is our only address, set it to the default
      current_user.postal_addresses.first.default! if (current_user.postal_addresses.count == 1)

      key = :updated
      case current_user.postal_addresses.count <=> old_address_count
      when -1
        key = :removed
      when 1
        key = :created
      end
      set_flash_message(:notice, key)
      redirect_to(settings_shipping_addresses_path)
    else
      render :index
    end
  end
end
