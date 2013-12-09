class FollowTombstone < ActiveRecord::Base
  belongs_to :user
  belongs_to :follower, :class_name => "User"

  scope :for_follow, lambda {|follow| where(user_id: follow.user_id).where(follower_id: follow.follower_id)}
end
