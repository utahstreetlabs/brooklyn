class FollowStory < LocalStory
  attr_reader :created_at, :follower, :followee

  def initialize(options = {})
    super
    @follower = options[:follower]
    @followee = options[:followee]
  end

  def type
    :follow
  end
end
