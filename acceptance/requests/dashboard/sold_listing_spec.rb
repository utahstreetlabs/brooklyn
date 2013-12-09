require './acceptance/spec_helper'

feature "Ship an item", %q{
  As a seller
  When I have shipped off an item somebody bought from me
  I want to let the system know I have shipped it
} do

  context "when listing uses basic shipping" do
    background do
      @order = given_order(:confirmed)
    end

    scenario "mark order shipped from dashboard", :js => true do
      login_as @order.listing.seller.email
      visit sold_dashboard_path
      expect(page).to have_content('Purchase confirmed')
      click_link 'Ship'
      shipping_modal_should_be_visible(@order.id)
      fill_in 'Tracking Number', :with => '1Z12345E0205271688'
      click_on 'Submit'
      expect(page).to have_content('Shipped')
      shipping_modal_should_be_hidden(@order.id)
    end

    def shipping_modal_should_be_visible(order_id)
      page.has_css?("#ship-order-#{order_id}-modal", :visible => true)
    end

    def shipping_modal_should_be_hidden(order_id)
      page.has_css?("#ship-order-#{order_id}-modal", :visible => false)
    end
  end

  context "when listing uses prepaid shipping" do
    background do
      @order = given_order(:confirmed)
      FactoryGirl.create(:shipping_option, listing: @order.listing)
    end

    scenario "visit manage sold prepaid listing from dashboard", js: true do
      login_as @order.listing.seller.email
      visit sold_dashboard_path
      expect(page).to have_content('Purchase confirmed')
      click_link 'Simple Ship'
      page_should_be_manage_prepaid_listing(@order.listing)
      expect(page).to have_content(I18n.t("listings.seller.confirmed_prepaid_shipping.title"))
    end

    def page_should_be_manage_prepaid_listing(listing)
      retry_expectations do
        expect(current_path).to eq(listing_path(listing))
      end
    end
  end
end
