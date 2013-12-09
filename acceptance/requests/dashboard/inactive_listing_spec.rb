require './acceptance/spec_helper'

feature "Manage inactive listings from dashboard" do

  background do
    login_as "starbuck@galactica.mil"
    @listing = FactoryGirl.create(:inactive_listing, seller: current_user)
  end

  scenario "publish listing", js: true do
    visit inactive_dashboard_path
    click_on "Publish"
    # XXX: timing issue in cap 1, retry will go away with cap 2, so just give it
    # a bit of breathing room
    retry_expectations(5) { expect(current_path).to eq(listing_path(@listing)) }
    expect(page).to have_content("SUCCESS! YOUR ITEM IS NOW LISTED")
  end

  scenario "edit listing" do
    visit inactive_dashboard_path
    click_on "Edit"
    retry_expectations { expect(current_path).to eq(edit_listing_path(@listing)) }
  end

  scenario "cancel listing", js: true do
    visit inactive_dashboard_path
    click_on "Cancel"
    accept_alert
    retry_expectations { expect(current_path).to eq(for_sale_dashboard_path) }
    expect(page).to have_content("The listing has been canceled")
  end
end
