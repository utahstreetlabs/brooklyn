require './acceptance/spec_helper'

feature "Change listing tags as admin" do
  let(:listing) { FactoryGirl.create(:active_listing) }

  background do
    given_tags ['raptor', 'viper']
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "add a tag" do
    visit edit_admin_listing_path(listing.id)
    fill_in "Tags", with: "raptor"
    click_on 'Save changes'
    current_path.should == admin_listing_path(listing.id)
    page.should have_content('raptor')
  end

  scenario "delete a tag" do
    listing.tags << Tag.find_by_name('raptor')
    visit edit_admin_listing_path(listing.id)
    fill_in "Tags", with: "raptor, viper"
    click_on 'Save changes'
    current_path.should == admin_listing_path(listing.id)
    page.should have_content('raptor')
    page.should have_content('viper')
  end
end