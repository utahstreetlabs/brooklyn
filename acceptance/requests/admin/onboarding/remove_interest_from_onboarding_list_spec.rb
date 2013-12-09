require './acceptance/spec_helper'

feature 'Remove interest from onboarding list', js: true do
  background do
    given_global_interest
    given_onboarding_interests(1)
    login_as 'roslin@galactica.mil', admin: true
  end

  scenario 'happily' do
    visit admin_onboarding_interests_path
    remove_interest
    page.should have_no_interests
  end

  def remove_interest
    find('[data-action=delete]').click
    accept_alert
  end

  matcher :have_no_interests do
    match do |page|
      page.all('[data-interest]').should be_empty
    end
  end
end
