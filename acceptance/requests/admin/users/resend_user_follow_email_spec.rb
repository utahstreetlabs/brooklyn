require './acceptance/spec_helper'

feature "Resend a user follow email" do
  let!(:user) { given_registered_user }

  background do
    viewer = login_as 'starbuck@galactica.mil', admin: true
    given_organic_follow user, viewer
    visit admin_user_path(user.id)
  end

  scenario "sends the email" do
    resend_user_follow_email
    email_should_be_sent
  end

  def resend_user_follow_email
    find('[data-action=resend-follow-email]').click
  end

  def email_should_be_sent
    retry_expectations do
      page.should have_flash_message(:notice, 'admin.users.follow_emails.created')
    end
  end
end
