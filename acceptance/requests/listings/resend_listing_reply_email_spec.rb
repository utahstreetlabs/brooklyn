require './acceptance/spec_helper'

feature "Resend a listing reply email" do
  let!(:listing) { given_listing }
  let!(:commenter) { given_registered_user }
  let!(:comment) { given_comment listing, commenter }
  let!(:replier) { given_registered_user }
  let!(:reply) { given_reply comment, replier }

  background do
    login_as 'starbuck@galactica.mil', admin: true
    visit listing_path(listing)
  end

  scenario "sends the email", js: true do
    resend_listing_reply_email
    email_should_be_sent
  end

  def resend_listing_reply_email
    find('[data-action=resend-reply-email]').click
  end

  def email_should_be_sent
    retry_expectations do
      page.should have_flash_message(:notice, 'listings.comments.replies.email_resent')
    end
  end
end
