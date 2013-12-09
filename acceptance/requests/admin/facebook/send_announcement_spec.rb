require './acceptance/spec_helper'

feature 'Send Facebook announcement via Notifications API', js: true do
  background do
    login_as 'roslin@galactica.mil', admin: true
  end

  scenario 'happily' do
    visit admin_facebook_announcements_path
    send_announcement
    announcement_should_be_sent
  end

  def send_announcement
    open_modal(:announcement)
    find('[data-action=announce]').click
  end

  def announcement_should_be_sent
    retry_expectations do
      modal_should_be_hidden(:announcement)
    end
    page.should have_flash_message(:notice, 'admin.facebook.announcements.sent')
  end
end
