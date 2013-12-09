require 'rising_tide/models/story'

# Models stories that reside in RisingTide.
class Story < LadonDecorator
  attr_accessor :actor
  attr_writer :latest_type_actor
  decorates RisingTide::Story

  # Returns whether or not the story's actor exists and is currently registered.
  #
  # @return [Boolean]
  def complete?
    not actor.nil?
  end

  # Returns whether or not the provided user is the actor who generated the activity underlying this story.
  #
  # @param [User] user the prospective actor of this story
  # @return [Boolean]
  def generated_by?(user)
    actor == user
  end

  # Returns the users involved in this story.
  #
  # @return [Array] the story's actor
  def users
    [actor]
  end

  # Returns whether or not the story represents a love action.
  def love?
    type == :listing_liked ||
      (types && types.is_a?(Hash) && types.keys.map(&:to_sym).include?(:listing_liked)) ||
      (types && types.is_a?(Array) && types.map(&:to_sym).include?(:listing_liked))
  end

  def ==(other)
    self.decorated == other.decorated
  end

  # Return a tuple consisting of the latest action in this story
  # and the id of actor who took the action
  #
  # Note that due to the current structure of digest stories we
  # won't necessarily return the latest action/actor for them.
  # Calvin says this is fine for now.
  def latest_type_actor_id
    case self.type
    when :listing_multi_actor then
      [action.to_sym, actor_ids.last]
    when :listing_multi_action then
      [types.last.to_sym, actor_id]
    when :listing_multi_actor_multi_action then
      t, aids = types.to_a.last
      [t.to_sym, aids.last]
    else
      [self.type.to_sym, actor_id]
    end
  end

  # map from story type to symbol representing the imperative form of the verb
  # associated with that type, so, "add" or "save" or "comment"
  TYPE_TO_IMPERATIVE =  {
    listing_activated: :add,
    listing_liked: :love,
    listing_commented: :comment,
    listing_saved: :save,
    listing_shared: :share,
    listing_sold: :sold
  }

  def latest_type_actor
    type, actor_id = latest_type_actor_id
    @latest_type_actor ||= [type, User.registered.where(id: actor_id).first]
  end

  def latest_imperative_action_actor
    type, actor = latest_type_actor
    [TYPE_TO_IMPERATIVE[type], actor]
  end

  def self.count_most_recent(since, options = {})
    decorated_class.count(options.merge(since: since))
  end

  def self.new_from_rising_tide(story)
    begin
      klass = "#{story.type.to_s.split('_').first.camelize}Story".constantize
    rescue NameError
      klass = self
    end
    klass.new(story)
  end

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

  def self.create_timeout
    Brooklyn::Application.config.magnolia.timeout.stories.create
  end
end
