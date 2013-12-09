require 'ladon'

class WelcomeFour < Ladon::Job
  @queue = :email

  def self.work(user_id)
    with_error_handling("send welcome series 4", user_id: user_id) do
      user = User.find(user_id)
      pcount = user.published_listing_count
      UserMailer.welcome_4(user).deliver unless pcount > 0
    end
  end
end
