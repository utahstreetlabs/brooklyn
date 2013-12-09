class Block < ActiveRecord::Base
  include Brooklyn::UniqueIndexEnforceable

  belongs_to :user
  belongs_to :blocker, :class_name => "User"

  attr_accessible :user, :blocker

  after_create { Follow.destroy_all(:user_id => blocker.id, :follower_id => user.id) }
end
