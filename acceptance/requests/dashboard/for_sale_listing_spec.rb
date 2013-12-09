require './acceptance/spec_helper'

feature "Manage listings for sale from dashboard" do

  background do
    login_as "starbuck@galactica.mil"
  end

  context "when taking actions" do
    before do
      @listing = FactoryGirl.create(:active_listing, seller: current_user)
    end

    scenario "edit listing" do
      visit for_sale_dashboard_path
      click_on "Edit"
      expect(current_path).to eq(edit_listing_path(@listing))
    end

    scenario "cancel listing", js: true do
      visit for_sale_dashboard_path
      click_on "Cancel"
      accept_alert
      expect(current_path).to eq(for_sale_dashboard_path)
      expect(page).to have_content("The listing has been canceled")
    end
  end

  context "when viewing listings" do
    context "when not free shipping" do
      before do
        @listing = FactoryGirl.create(:active_listing, seller: current_user, price: 100, shipping: 3)
      end

      scenario "it is displayed as the amount to seller on dashboard" do
        visit for_sale_dashboard_path
        listing_details_shipping_should_be(@listing, "$3.00")
      end
    end

    context "when free shipping" do
      before do
        @listing = FactoryGirl.create(:active_listing, seller: current_user, price: 100, shipping: 0)
      end

      scenario "it is displayed as Free to the seller on dashboard" do
        visit for_sale_dashboard_path
        listing_details_shipping_should_be(@listing, "Free")
      end
    end

    def listing_details_shipping_should_be(listing, shipping)
      # Selects the fourth column element (shipping) from the table
      expect(page.find("[data-role=shipping]").text).to eq(shipping)
    end
  end
end
