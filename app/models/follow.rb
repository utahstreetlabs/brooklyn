require 'brooklyn/sprayer'
require 'brooklyn/unique_index_enforceable'

class Follow < ActiveRecord::Base
  include Brooklyn::UniqueIndexEnforceable
  include StiOverride

  #Hack to override STI.  Uses ints mapped to classnames to save DB space.  See: StiOverride
  FOLLOW_TYPES = {
    0 => "AutomaticFollow",
    1 => "InterestFollow",
    2 => "OrganicFollow",
    3 => "FollowAll",
    4 => "DefaultFollow"
  }

  belongs_to :user
  belongs_to :follower, :class_name => "User"

  # a pseudo-attribute that governs whether or not the followee is to be notified through any channel of the follow
  attr_accessor :suppress_followee_notifications, :suppress_fb_follow

  attr_accessible :user, :follower, :follow_type, :suppress_followee_notifications, :suppress_fb_follow

  def type_code
    self.class.type_code
  end

  def followee
    user
  end

  def refollow?
    @refollow ||= FollowTombstone.for_follow(self).exists?
  end

  def post_to_facebook!
    if self.follower.allow_autoshare?(:user_followed, :facebook)
      Facebook::OpenGraphFollow.enqueue(self.id)
    end
  end

  def post_notification_to_facebook!
    return unless feature_enabled?(:networks, :facebook, :notifications, :action, :friend_follow)
    Facebook::NotificationFollow.enqueue(self.id)
  end

  after_commit on: :create do
    options = {
      notify_followee: !suppress_followee_notifications,
      suppress_fb_follow: suppress_fb_follow
    }
    Follows::AfterCreationJob.enqueue(self.id, options)
  end

  after_commit on: :destroy do
    FollowTombstone.find_or_create_by_user_id_and_follower_id(self.user_id, self.follower_id)
    options = {
      follow_type: self.class.name
    }
    Follows::AfterDestructionJob.enqueue(self.follower_id, self.user_id, options)
    # queue up the open graph unfollow here rather than in the AfterDestructionJob since
    # the follow (and therefore the fb_subscription_id) won't exist at that point
    if self.fb_subscription_id
      Facebook::OpenGraphUnfollow.enqueue(self.follower_id, self.fb_subscription_id)
    end
  end

  def self.follow_type_id(class_name)
    FOLLOW_TYPES.invert[class_name.to_s]
  end

  def self.type_code
    name.underscore.gsub(/_follow/, '').to_sym
  end

  def self.follow_exists?(followee_id, follower_id)
    exists?(user_id: followee_id, follower_id: follower_id)
  end
end
