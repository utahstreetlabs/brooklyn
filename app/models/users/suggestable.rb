require 'active_support/concern'

module Users
  module Suggestable
    extend ActiveSupport::Concern

    included do
      has_many :suggestions, class_name: 'UserSuggestion', dependent: :destroy
      has_many :suggested_for_interests, through: :suggestions, source: :interest
    end

    def suggested_for_interest?(interest)
      suggestion_for_interest(interest).present?
    end

    def suggestion_for_interest(interest)
      suggested_for_interests.detect { |i| i == interest }
    end

    def suggest_for_interests!(ids)
      ids = Array.wrap(ids).map(&:to_i)
      logger.debug("Suggesting user #{self.id} for interests #{ids}")
      self.suggested_for_interest_ids = ids
    end
  end
end
