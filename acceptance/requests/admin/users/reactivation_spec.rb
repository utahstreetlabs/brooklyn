require './acceptance/spec_helper'

feature "Reactivate user" do
  background do
    login_as 'roslin@galactica.mil', admin: true
  end

  let!(:user) { given_inactive_user email: "billy@galactica.gov" }

  scenario 'happily' do
    visit admin_user_path(user.id)
    reactivate_user
    user_state.should be_active
  end

  def reactivate_user
    reactivate_button.click
  end

  def reactivate_button
    find('[data-action=reactivate]')
  rescue Capybara::ElementNotFound
    nil
  end

  def user_state
    find('[data-role=registration-state]').text.strip
  end

  matcher :be_active do
    match do |state|
      state.should == 'Registered'
    end
  end
end
