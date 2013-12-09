class ListingDefaultStory < LocalStory
  attr_reader :actor_id
  attr_accessor :latest_type_actor

  def initialize(actor_id, options = {})
    super(options)
    @actor_id = actor_id
  end

  def type
    :listing_default
  end

  def latest_type_actor_id
    [type.to_sym, actor_id]
  end

  def latest_imperative_action_actor
    type, actor = latest_type_actor
    [:listed, actor]
  end
end
