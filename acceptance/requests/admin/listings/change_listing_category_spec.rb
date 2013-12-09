require './acceptance/spec_helper'

feature "Change listing category as admin" do
  let(:listing) { FactoryGirl.create(:active_listing) }

  background do
    given_category 'Polearms'
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "changes the listing's category" do
    visit edit_admin_listing_path(listing.id)
    select('Polearms', from: 'Category')
    click_on 'Save changes'
    current_path.should == admin_listing_path(listing.id)
    page.should have_content('Polearms')
  end
end
