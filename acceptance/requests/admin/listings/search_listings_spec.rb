require './acceptance/spec_helper'

feature "Search listings as admin" do
  let!(:listing1) { FactoryGirl.create(:active_listing) }
  let!(:listing2) { FactoryGirl.create(:active_listing) }

  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "finds listing by title" do
    visit admin_listings_path
    search_datagrid listing1.title
    page.should have_content(listing1.title)
    page.should_not have_content(listing2.title)
  end
end
