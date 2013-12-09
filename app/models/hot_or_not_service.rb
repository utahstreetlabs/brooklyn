require 'pyramid/models/user'

class HotOrNotService
  include Ladon::Logging

  attr_reader :user

  def initialize(user)
    @user = user
  end

  # Returns whether or not the user is required to go through the hot or not process. This is true when the user has
  # registered since the time given by +self.class.config.registered_since+.
  def required?
    user.registered_since?(self.class.config.registered_since)
  end

  # Returns whether or not the user has completed the process. This is true when the user has liked the required
  # number of listings given by +self.class.config.likes_needed_for_completion+.
  def completed?
    user.likes_count >= self.class.config.likes_needed_for_completion
  end

  # Returns a relation describing listings suggested for the user's next hot or not choice.
  #
  # @return [ActiveRecord::Relation]
  def suggestions(options = {})
    if user.likes_count < self.class.config.likes_needed_for_custom
      logger.debug("Loading trending hot or not suggestions")
      #XXX-hot-or-not this needs to filter out stuff we've already liked
      ids = Listing.recently_liked(self.class.config.trending.window,
                                   per: self.class.config.trending.limit,
                                   exclude_liked_by_users: user.id)
    else
      logger.debug("Loading clustered hot or not suggestions")
      # probably need to tune the number of choices to return
      ids = Pyramid::User.hot_or_not_suggestions(user.id)
    end
    Listing.visible(id: ids, exclude_disliked_by: user)
  end

  def self.config
    Brooklyn::Application.config.hot_or_not
  end
end
