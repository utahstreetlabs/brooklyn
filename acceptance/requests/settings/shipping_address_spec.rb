require './acceptance/spec_helper'

feature "Manage shipping addresses" do
  include_context 'viewing shipping settings'

  scenario "add a shipping address", js: true do
    add_shipping_address
    shipping_address_creation_should_succeed
  end

  scenario "edit an existing shipping address", js: true do
    update_shipping_address
    shipping_address_update_should_succeed
  end

  scenario "delete an existing shipping address", js: true do
    delete_shipping_address
    shipping_address_delete_should_succeed
  end

  scenario "make an address default", js: true do
    add_shipping_address
    shipping_address_creation_should_succeed
    set_default_shipping_address
    shipping_address_default_should_succeed
    shipping_address_default_should_be_first
  end

  scenario "does not display shipping addresses associated with an order", js: true do
    @order = given_order(:confirmed)
    @address = PostalAddress.all.first
    @order.shipping_address.id.should_not == @address.id
    shipping_addresses_include(@address).should be_true
    shipping_addresses_include(@order.shipping_address).should be_false
  end

  scenario "delete the shipping address associated with an order", js: true do
    @order = given_order(:confirmed)
    @address = PostalAddress.all.first
    @order.shipping_address.id.should_not == @address.id
    within "#edit-address-#{@address.id}" do
      click_link "Delete"
    end
    wait_for(2)
    accept_alert
    shipping_address_delete_should_succeed
  end
end
