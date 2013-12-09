require './acceptance/spec_helper'

feature "Resend a listing love email" do
  let!(:listing) { given_listing }

  background do
    viewer = login_as 'starbuck@galactica.mil', admin: true
    given_like listing, viewer
    visit admin_listing_path(listing.id)
  end

  scenario "sends the email" do
    resend_listing_love_email
    email_should_be_sent
  end

  def resend_listing_love_email
    find('[data-action=resend-love-email]').click
  end

  def email_should_be_sent
    retry_expectations do
      page.should have_flash_message(:notice, 'admin.listings.love_emails.created')
    end
  end
end
