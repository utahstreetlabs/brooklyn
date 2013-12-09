class Listings::ReturnAddressController < ApplicationController
  include Controllers::ListingScoped

  respond_to :json

  set_listing
  require_listing state: :sold, flash: :no_longer_active
  require_seller
  require_order status: :confirmed

  def create
    # Populate @ship_from and @new_address here so that renders of the modal are (re)populated correctly.
    @ship_from = ShipFrom.create(@listing, current_user.sorted_shipping_addresses.all)
    @new_address = current_user.shipping_addresses.build(params[:new_address])
    if @new_address.save
      @listing.copy_master_return_address!(@new_address)
      data = {
        alert: view_context.bootstrap_flash(:notice, localized_flash_message(:created)),
        refresh: render_to_string(partial: '/listings/return_address/details.html', locals: {listing: @listing})
      }
      render_jsend(success: data)
    else
      data = {modal: render_to_string(partial: '/listings/return_address/edit_modal.html',
                                      locals: {listing: @listing, ship_from: @ship_from, new_address: @new_address}),
              errors: @new_address.errors.full_messages}
      render_jsend(fail: data)
    end
  end

  # The return address being updated is an old address selected via radio button and populated
  # via +params[:ship_from]+)
  def update
    # Populate @ship_from and @new_address here so that renders of the modal are (re)populated correctly.
    @ship_from = ShipFrom.create(@listing, current_user.sorted_shipping_addresses.all)
    @new_address = PostalAddress.new_shipping_address

    begin
      address = current_user.postal_addresses.find(params[:ship_from][:address_id]) if params[:ship_from]
      @listing.copy_master_return_address!(address.id)
      data = {
        alert: view_context.bootstrap_flash(:notice, localized_flash_message(:updated)),
        refresh: render_to_string(partial: '/listings/return_address/details.html', locals: {listing: @listing})
      }
      render_jsend(success: data)
    rescue ActiveRecord::RecordNotFound
      # If we couldn't find an address that's already saved to the user's address book, that's an error.
      render_jsend(error: {alert: view_context.bootstrap_flash(:error, localized_flash_message(:error_updating))})
    end
  end
end
