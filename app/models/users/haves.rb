module Users
  module Haves
    extend ActiveSupport::Concern
    include Stats::Trackable

    included do
      # needs class_name because otherwise AR thinks it's "Hafe"
      has_many :haves, class_name: 'Have', dependent: :destroy
    end

    # Ensures the user has a have for this item, creating it if necessary, and returns the have.
    #
    # @return [Have]
    def has_item!(item)
      haves.create!(item_id: item.id, user_id: self.id)
    rescue ActiveRecord::RecordNotUnique
      have_for_item(item) or
        raise ActiveRecord::RecordNotFound
    end

    def has_item?(item)
      haves.where(item_id: item.id).any?
    end

    def have_for_item(item)
      haves.where(item_id: item.id).first
    end
  end
end
