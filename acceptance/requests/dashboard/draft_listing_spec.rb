require './acceptance/spec_helper'

feature "Manage draft listings from dashboard" do

  background do
    login_as "starbuck@galactica.mil"
    @listing = FactoryGirl.create(:incomplete_listing, seller: current_user)
  end

  scenario "complete listing" do
    visit draft_dashboard_path
    click_on "Complete"
    expect(current_path).to eq(setup_listing_path(@listing))
  end

  scenario "cancel listing", js: true do
    visit draft_dashboard_path
    click_on "Cancel"
    accept_alert
    expect(current_path).to eq(for_sale_dashboard_path)
    expect(page).to have_content("The listing has been canceled")
  end
end
