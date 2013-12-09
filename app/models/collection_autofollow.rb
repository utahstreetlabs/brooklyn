class CollectionAutofollow < ActiveRecord::Base
  belongs_to :collection
  belongs_to :interest

  attr_accessible :collection_id, :interest_id

  scope :by_name, joins(:interest).order(interest: :name)

  def self.count_by_interest
    count(:all, select: :interest_id, group: :interest_id)
  end
end
