require './acceptance/spec_helper'

feature "Cancel listings", %q{
  In order feel confident my decision to list an item is not permanent
  As a registered user
  I want to be able to cancel a listing
} do

  background do
    given_registered_user email:     "starbuck@galactica.mil"
    login_as "starbuck@galactica.mil"
  end

  let! (:listing) do
    given_listing title: "Used Viper",
                  seller: "starbuck@galactica.mil"
  end

  scenario "cancel listing", js: true do
    viper_should_be_listed
    visit listing_path(listing)
    click_link "Cancel listing"
    accept_alert
    wait_a_sec_for_selenium
    expect(current_path).to eq(for_sale_dashboard_path)
    viper_should_not_be_listed
  end

  def viper_should_be_listed
    visit browse_for_sale_path
    expect(page).to have_content "Used Viper"
  end

  def viper_should_not_be_listed
    visit browse_for_sale_path
    expect(page).to have_no_content "Used Viper"
  end
end
