class UserAutofollow < ActiveRecord::Base
  belongs_to :user
  acts_as_list

  attr_accessible :position

  scope :by_position, order(:position)
end
