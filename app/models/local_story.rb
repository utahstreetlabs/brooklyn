# A base class for stories that are sourced from Brooklyn rather than RisingTide.
class LocalStory
  attr_reader :created_at

  def initialize(options = {})
    @created_at = Time.zone.now
  end

  # Returns a unique symbol identifying the type of story. This is generally more granular than the story subclass
  # itself. For example, the story types +:listing_commented+, +:listing_liked+ and +:listing_sold+ could all be
  # represented by a ListingStory subclass.
  #
  # Subclasses must override this method.
  #
  # @return [Symbol]
  def type
    raise UnimplementedError
  end

  # Returns +true+ if the story has resolved all of its associations and has enough associated objects that it can
  # be fully rendered. A story might be incomplete if, for example, rendering it depends on an associated user but
  # that user no longer exists in the system. This implementation always returns +true+.
  #
  # Subclasses should override this method if they depend on associated objects for rendering.
  #
  # @return [Boolean]
  def complete?
    true
  end

  # Provides a hook for efficiently loading associated objects from backing storage. This implementation does nothing.
  #
  # Subclasses should override this method if they depend on associated objects for rendering and those objects were
  # not provided at instantiation.
  def self.resolve_associations(stories, options = {})
    # no-op
  end
end
