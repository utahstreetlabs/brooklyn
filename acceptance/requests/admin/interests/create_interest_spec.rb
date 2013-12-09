require './acceptance/spec_helper'

feature 'Create interest' do
  background do
    login_as 'roslin@galactica.mil', admin: true
  end

  scenario 'happily' do
    visit new_admin_interest_path
    create_interest
    current_path.should == admin_interests_path
    page.should have_interest
  end

  def create_interest
    fill_in 'Name', with: 'Jazzercise'
    choose 'Female'
    attach_file "Cover photo", fixture("handbag.jpg")
    check 'Add to onboarding'
    click_on 'Save changes'
  end

  matcher :have_interest do
    match do |page|
      page.should have_css('[data-interest]')
    end
  end
end
