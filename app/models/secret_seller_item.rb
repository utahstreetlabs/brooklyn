require 'brooklyn/sprayer'

class SecretSellerItem < ActiveRecord::Base
  include Brooklyn::Sprayer

  MINIMUM_PRICE = Brooklyn::Application.config.pricing.minimum
  CONDITIONS = [:new, :used, :new_with_tags, :like_new, :handmade]

  belongs_to :seller, class_name: 'User'

  attr_accessible :title, :description, :price, :condition, :photo
  mount_uploader :photo, SecretSellerItemPhotoUploader

  validates :title, presence: true, length: {maximum: 80, allow_blank: true}
  validates :description, presence: true
  validates :price, presence: true,
    numericality: {
      greater_than_or_equal_to: MINIMUM_PRICE,
      minimum_price: ActionController::Base.helpers.number_to_currency(MINIMUM_PRICE)
    }
  validates :condition, presence: true, inclusion: {in: CONDITIONS.map(&:to_s), allow_blank: true}
  validates :photo, presence: true

  after_commit on: :create do
    send_email(:submitted, self)
  end
end
