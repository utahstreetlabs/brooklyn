require './acceptance/spec_helper'

feature "Change listing tags as admin" do
  let(:listing) { FactoryGirl.create(:active_listing) }

  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "happily" do
    visit edit_admin_listing_path(listing.id)
    fill_in "Title", with: "OMG New Title"
    click_on 'Save changes'
    current_path.should == admin_listing_path(listing.id)
    page.should have_content("OMG New Title")
  end
end