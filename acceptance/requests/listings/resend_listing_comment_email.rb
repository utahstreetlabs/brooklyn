require './acceptance/spec_helper'

feature "Resend a listing comment email" do
  let!(:listing) { given_listing }
  let!(:commenter) { given_registered_user }
  let!(:comment) { given_comment listing, commenter }

  background do
    login_as 'starbuck@galactica.mil', admin: true
    visit listing_path(listing)
  end

  scenario "sends the email", js: true do
    resend_listing_comment_email
    email_should_be_sent
  end

  def resend_listing_comment_email
    find('[data-action=resend-comment-email]').click
  end

  def email_should_be_sent
    retry_expectations do
      page.should have_flash_message(:notice, 'listings.comments.email_resent')
    end
  end
end
