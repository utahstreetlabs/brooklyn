# Models stories about users in a user's network.
class NetworkStory < Story
  decorates RisingTide::Story

  # @param [RisingTide::Story] the decorated story
  # @return [NetworkStory] the specifically-typed network story
  def self.new_from_rising_tide(story)
    klazz = case story.type
            when :user_followed then NetworkFollowStory
            when :user_invited, :user_piled_on then NetworkInviteStory
            else self
            end
    klazz.new(story)
  end
end
