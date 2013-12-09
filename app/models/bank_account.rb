require 'balanced'

class BankAccount < DepositAccount
  has_many :payments, class_name: 'BankPayment'

  attr_accessible :name, :number, :routing_number, :last_four
  attr_accessor :number, :routing_number

  validates :name, presence: true, length: {maximum: 64}, on: :create
  # Balanced does not do any syntax of account numbers checking either
  validates :number, presence: true, length: {maximum: 32}, on: :create, unless: -> { last_four.present? }
  # same check that Balanced does
  validates :routing_number, presence: true, routing_number: true , on: :create

  def display_name
    name
  end

  def to_balanced_params
    {
      name: name,
      account_number: number,
      bank_code: routing_number
    }
  end
end
