require 'ladon'

class WelcomeThree < Ladon::Job
  @queue = :email

  def self.work(user_id)
    with_error_handling("send welcome series 3", user_id: user_id) do
      user = User.find(user_id)
      UserMailer.welcome_3(user).deliver
    end
  end
end
