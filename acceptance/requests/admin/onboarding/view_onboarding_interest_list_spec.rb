require './acceptance/spec_helper'

feature 'View onboarding interest list' do
  let(:interest_count) { 3 }

  background do
    given_global_interest
    given_onboarding_interests(interest_count)
    login_as 'roslin@galactica.mil', admin: true
  end

  scenario 'happily' do
    visit admin_onboarding_interests_path
    page.should have_interests
  end

  matcher :have_interests do
    match do |page|
      page.all('[data-interest]').size.should == interest_count
    end
  end
end
