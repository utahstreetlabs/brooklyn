class UserFollowNotification < Notification
  attr_accessor :follower

  def complete?
    !follower.nil?
  end
end
