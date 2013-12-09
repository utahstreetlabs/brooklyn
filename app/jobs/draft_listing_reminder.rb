require 'ladon'

class DraftListingReminder < Ladon::Job
  @queue = :email

  def self.work(user_id)
    with_error_handling("send draft listing reminder", user_id: user_id) do
      user = User.find(user_id)
      draft = user.draft_listings.first
      UserMailer.draft_listing_reminder(user, draft).deliver if draft
    end
  end
end
