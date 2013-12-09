require 'active_support/concern'

module Collections
  module Autofollowable
    extend ActiveSupport::Concern

    included do
      has_many :autofollows, class_name: 'CollectionAutofollow', dependent: :destroy
      has_many :autofollowed_for_interests, through: :autofollows, source: :interest
    end

    def autofollow_for_interests!(ids)
      ids = Array.wrap(ids).map(&:to_i)
      logger.debug("Autofollow collection #{self.id} for interests #{ids}")
      self.autofollowed_for_interest_ids = ids
    end

    def autofollowed_for_interest?(interest)
      autofollow_for_interest(interest).present?
    end

    def autofollow_for_interest(interest)
      autofollowed_for_interests.where(id: interest.id).first
    end

    def autofollowed?
      autofollows.any?
    end

    module ClassMethods
      # Returns the list of collections that are auto-followed during signup.
      def autofollow_list
        CollectionAutofollow.includes(:collection).map(&:collection)
      end

      def autofollow_list_for_interest(interest)
        autofollow_list_for_interests([interest])
      end

      def autofollow_list_for_interests(interests)
        per_interest = Brooklyn::Application.config.collections.autofollow.per_interest
        autofollows = CollectionAutofollow.where(interest_id: interests).includes(:collection)
        idx = autofollows.each_with_object({}) do |af, m|
          m[af.interest_id] ||= []
          m[af.interest_id] << af
        end
        collection_lists = interests.map do |i|
          idx.fetch(i.id, []).sample(per_interest).map(&:collection)
        end
        collection_lists.flatten.uniq
      end
    end
  end
end
