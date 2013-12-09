class PriceAlert < ActiveRecord::Base
  belongs_to :listing
  belongs_to :user

  module Discounts
    NONE = 0
    ANY = 100
    STEP = 25

    def self.all
      @all ||= (NONE+STEP...ANY).step(STEP)
    end

    def self.random
      all.sample
    end
  end

  # user is not accessible as there is no use case that requires a price alert to be created any other way than
  # +user.build_price_alert(listing, threshold: 0)+.
  attr_accessible :listing, :threshold

  # 100 represents "any change"
  validates :threshold, presence: true, numericality: {
              integer_only: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100, allow_blank: true
            }
end
