class NetworkFollowStory < NetworkStory
  decorates RisingTide::Story
  attr_accessor :followee

  # Returns the users involved in this story.
  #
  # @return [Array] the story's actor and followee
  def users
    super + [followee]
  end

  # Returns whether or not the story's followee exists.
  #
  # @return [Boolean]
  def complete?
    super and not followee.nil?
  end

  # Returns the provided array of stories after populating each story with its associated followee. Only
  # registered followees are fetched.
  #
  # @param [Array] stories
  # @return [Array] the same list of stories, now populated (hopefully) with followees
  def self.eager_fetch_followees(stories)
    follow_stories = stories.select {|s| s.is_a?(self)}
    user_ids = follow_stories.map(&:followee_id).compact.uniq
    user_idx = User.with_people(user_ids, :registered).inject({}) {|m, u| m.merge(u.id => u)}
    follow_stories.each {|s| s.followee = user_idx[s.followee_id]}
    stories
  end
end
