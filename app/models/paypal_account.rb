require 'balanced'

class PaypalAccount < DepositAccount
  has_many :payments, class_name: 'PaypalPayment'

  attr_accessible :email, :email_confirmation
  attr_accessor :email_confirmation

  validates :email, presence: true, confirmation: true

  def display_name
    email
  end

  def to_balanced_params
    self.class.marketplace_bank_account_params
  end
end
