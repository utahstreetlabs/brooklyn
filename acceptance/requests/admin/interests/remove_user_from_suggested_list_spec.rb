require './acceptance/spec_helper'

feature 'Remove user from suggested list', js: true do
  let(:interest) { given_suggested_user_list(1) }

  background do
    given_global_interest
    login_as 'roslin@galactica.mil', admin: true
  end

  scenario 'happily' do
    visit admin_interest_path(interest)
    remove_user
    page.should have_no_users
  end

  def remove_user
    find('[data-action=delete]').click
    accept_alert
  end

  matcher :have_no_users do
    match do |page|
      page.all('[data-user]').should be_empty
    end
  end
end
