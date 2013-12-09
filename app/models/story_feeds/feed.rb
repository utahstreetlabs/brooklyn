require 'rising_tide/models/feed'

# Models stories that reside in RisingTide.
module StoryFeeds
  class Feed < LadonDecorator
    decorates RisingTide::Feed

    # Returns the provided array of stories after populating each story with its associated actor. If a story refers to
    # an actor +registered+ state, then the story will not be completely populated.
    #
    # @param [Array] stories
    # @return [Array] the same list of stories, now populated (hopefully) with actors
    def self.eager_fetch_actors(stories)
      user_ids = stories.map(&:actor_id).compact.uniq
      if user_ids.any?
        user_idx = User.with_people(user_ids, :registered).inject({}) {|m, u| m.merge(u.id => u)}
        stories.each {|s| s.actor = user_idx[s.actor_id]}
      end
      stories
    end

    # Returns the provided stories after resolving actor associations.
    #
    # @param [Array] stories the stories whose associations are to be resolved
    # @param [Hash] options options controlling association resolution
    # @return [Array] the stories with resolved associations
    def self.resolve_associations(stories, options = {})
      stories = super(stories, options)
      stories = eager_fetch_actors(stories)
      stories
    end
  end
end
