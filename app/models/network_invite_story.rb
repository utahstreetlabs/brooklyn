class NetworkInviteStory < NetworkStory
  decorates RisingTide::Story
  attr_accessor :invitee

  # Returns whether or not the story's invitee exists.
  #
  # @return [Boolean]
  def complete?
    super and not invitee.nil?
  end

  # Returns the provided array of stories after populating each story with its associated invitee.
  #
  # @param [Array] stories
  # @return [Array] the same list of stories, now populated (hopefully) with invitees
  def self.eager_fetch_invitees(stories)
    invite_stories = stories.select {|s| s.is_a?(self)}
    profile_ids = invite_stories.map(&:invitee_profile_id).compact.uniq
    profile_idx = Profile.find(profile_ids).inject({}) {|m, p| m.merge(p.id => p)}
    invite_stories.each {|s| s.invitee = profile_idx[s.invitee_profile_id]}
    stories
  end
end
