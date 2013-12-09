require 'ladon'

class WelcomeTwo < Ladon::Job
  @queue = :email

  def self.work(user_id)
    with_error_handling("send welcome series 2", user_id: user_id) do
      user = User.find(user_id)
      UserMailer.welcome_2(user).deliver
    end
  end
end
