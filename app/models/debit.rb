class Debit < ActiveRecord::Base
  belongs_to :credit
  belongs_to :order

  validates :amount, presence: true, numericality: {greater_than: 0}

  attr_accessible :amount, :expires_at
end
