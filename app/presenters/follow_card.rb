class FollowCard < UserCard
  def initialize(story, viewer, options = {})
    super
    self.user = story.followee
  end

  def follower
    viewer
  end

  def followee
    user
  end
end
