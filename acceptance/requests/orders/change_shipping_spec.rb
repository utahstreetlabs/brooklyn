require './acceptance/spec_helper'

feature "Buyer changes shipping details for an item", %q{
  As a buyer
  Before an item has been shipped
  I want to change the shipping details for the item
} do

  background do
    @order = given_order(:confirmed)
    @address = PostalAddress.all.first
    FactoryGirl.create(:shipping_address, user: @order.buyer, name: "foo", line1: "foo st")
    FactoryGirl.create(:shipping_address, user: @order.buyer, name: "bar", line1: "bar st")
  end

  scenario "change shipping address", :js => true do
    pending "infuriatingly, does not work on the build machine"
    login_as @order.buyer.email
    visit listing_path(@order.listing)
    click_on "Order details"
    retry_with_sleep do
      # XXX: on the build machine, this element can't be found
      find('[data-role=change-shipping]', visible: true).click
    end
    choose("foo")
    click_on "Save"
    click_on "Order details"
    within '.address' do
      page.should have_content('foo st')
    end
    PostalAddress.where(id: @address.id).should be_empty
  end
end
