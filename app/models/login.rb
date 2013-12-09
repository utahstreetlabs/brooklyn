require 'ladon/model'

class Login < Ladon::Model
  attr_accessor :email, :password, :remember_me, :user, :facebook_token, :facebook_signed

  validates :email, presence: true
  validates :password, presence: true
  validate :authenticates

  def remember_me?
    remember_me == '1' || remember_me == true
  end

  def authenticates
    if email.present? && password.present?
      user = User.authenticate(email, password)
      if user
        @user = user
      else
        errors.add(:base, :inauthentic)
      end
    end
  end
end
