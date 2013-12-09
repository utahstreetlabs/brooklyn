require './acceptance/spec_helper'

feature 'Edit interest' do
  let!(:interest) { FactoryGirl.create(:interest, {name: "Handbags", onboarding: '1'}) }

  background do
    login_as 'roslin@galactica.mil', admin: true
  end

  scenario 'happily' do
    visit edit_admin_interest_path(interest)
    edit_interest
    current_path.should == admin_interests_path
    page.should have_content('Purses')
    page.should_not have_content('Handbags')
  end

  def edit_interest
    fill_in 'Name', with: 'Purses'
    choose 'Female'
    attach_file "Cover photo", fixture("handbag.jpg")
    check 'Add to onboarding'
    click_on 'Save changes'
  end

  matcher :have_edited_interest do
    match do |page|
      page.should have_css('[data-interest]')
    end
  end
end
