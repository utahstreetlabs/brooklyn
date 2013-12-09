require 'ladon'

class WelcomeFive < Ladon::Job
  @queue = :email

  def self.work(user_id)
    with_error_handling("send welcome series 5", user_id: user_id) do
      user = User.find(user_id)
      UserMailer.welcome_5(user).deliver unless user.direct_invite_count > 10
    end
  end
end
