require 'weighted_randomizer'

module Users
  module Interests
    extend ActiveSupport::Concern

    # Number of interests this user must select to get a customized feed
    def interests_remaining_count
      [Brooklyn::Application.config.users.interests.minimum_needed_to_build_feed - self.interests.count, 0].max
    end

    def interests_in(ids)
      interests.where(id: ids)
    end

    # Return listings in the given interest that have been liked by this user.
    #
    # Because likes are stored in a separate database, we must pick a
    # maximum number of them to use when building the listing query.
    # The default is defined in Rails configuration, but this value
    # can also be set using the `max_likes` option to this method
    #
    # @param [Hash] options
    # @option options [Integer] :max_likes the maximum number of likes to return
    def liked_in_interest(interest, options = {})
      max_likes = options[:max_likes] || Brooklyn::Application.config.users.interests.max_interest_likes
      likes = options[:likes] || self.likes(per: max_likes)
      interest.listings.where(id: likes.map(&:listing_id))
    end

    # Return dislikes this user has created on listings in the given interest.
    def dislikes_in_interest(interest)
      Dislike.joins(listing: {collections: :autofollowed_for_interests}).where(interests: {id: interest.id}, user_id: self.id)
    end

    # Calculate the given interest's score for this user.
    #
    # A user's interest score is defined as:
    #
    # (num of likes by the user under this interest) /
    #   (num of user likes + dislikes by the user under this interest)
    def interest_score(interest, options = {})
      likes = liked_in_interest(interest, options).count
      dislikes = dislikes_in_interest(interest).count
      if (likes + dislikes) == 0
        0
      else
        likes.to_f / (likes + dislikes).to_f
      end
    end

    # Calculate interest scores for this user for every user in the system
    #
    # @returns a Hash from interest to score
    def interest_scores
      max_likes = Brooklyn::Application.config.users.interests.max_interest_likes
      likes = self.likes(per: max_likes)
      Interest.all_but_global.each_with_object({}) do |interest, m|
        m[interest] = interest_score(interest, likes: likes)
      end
    end

    # Pick a random interest for this user. The likelihood of a
    # particular interest being selected is dependent on its interest
    # score for this user.
    def random_interest
      WeightedRandomizer.new(interest_scores).sample
    end
  end
end
