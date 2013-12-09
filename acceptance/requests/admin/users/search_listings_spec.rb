require './acceptance/spec_helper'

feature "Search listings as admin" do
  let!(:user1) { FactoryGirl.create(:registered_user) }
  let!(:listing1) { FactoryGirl.create(:active_listing, seller: user1) }
  let!(:listing2) { FactoryGirl.create(:active_listing, seller: user1) }

  background do
    given_global_interest
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "finds all listings for user" do
    visit admin_user_path(user1.id)
    click_user_listings
    expect(page).to have_content(listing1.title)
    expect(page).to have_content(listing2.title)
  end

  scenario "can view individual listing for user" do
    visit admin_user_path(user1.id)
    click_user_listings
    expect(page).to have_content(listing1.title)
    click_user_listing(listing1.id)
    expect(page).to have_css("title:contains('Admin: #{listing1.title}')")
  end

  private

  def click_user_listings
    find('[data-role=user-listings] a').click
  end

  def click_user_listing(listing_id)
    find("[data-role=user-listing-#{listing_id}] a").click
  end
end
