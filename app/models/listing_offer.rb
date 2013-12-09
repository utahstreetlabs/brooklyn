class ListingOffer < ActiveRecord::Base
  belongs_to :user
  belongs_to :listing

  attr_accessible :amount, :duration, :message
  validates :amount, presence: true, numericality: {greater_than: 0.00, allow_blank: true}
  validates :duration, presence: true, numericality: {only_integer: true, greater_than: 0, allow_blank: true}

  after_commit on: :create do
    ListingOffers::AfterCreationJob.enqueue(self.id)
  end
end
