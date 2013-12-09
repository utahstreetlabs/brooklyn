require './acceptance/spec_helper'

feature "Manage suspended listings from dashboard" do

  background do
    login_as "starbuck@galactica.mil"
    @listing = FactoryGirl.create(:suspended_listing, seller: current_user)
  end

  scenario "edit listing" do
    visit suspended_dashboard_path
    click_on "Edit"
    expect(current_path).to eq(edit_listing_path(@listing))
  end

  scenario "cancel listing", js: true do
    visit suspended_dashboard_path
    click_on "Cancel"
    accept_alert
    expect(current_path).to eq(for_sale_dashboard_path)
    page.should have_content("The listing has been canceled")
  end
end
