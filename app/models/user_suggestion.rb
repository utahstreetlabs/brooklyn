class UserSuggestion < ActiveRecord::Base
  belongs_to :user
  belongs_to :interest

  attr_accessible :user_id, :interest_id, :position

  acts_as_list scope: :interest_id, top_of_list: 0

  scope :by_position, order(:position)
  scope :by_name, joins(:interest).order(interest: :name)

  def self.count_by_interest
    count(:all, select: :interest_id, group: :interest_id)
  end
end
