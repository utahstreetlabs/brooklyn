module Users
  module Wants
    extend ActiveSupport::Concern
    include Stats::Trackable

    included do
      has_many :wants, dependent: :destroy
    end

    # Returns an existing want, or +nil+ if it doesn't exist.
    def find_want_by_id(id)
      wants.where(id: id).first
    end

    # Creates a want for this item.
    #
    # @raise [ActiveRecord::RecordInvalid] if the attributes are invalid
    # @raise [ActiveRecord::RecordNotUnique] if the user already has a want for this item
    # @return [Want]
    def wants_item!(item, attributes = {})
      wants.create!(attributes.reverse_merge(item_id: item.id, user_id: self.id))
    end

    # Returns whether or not this user has an existing want for +item+.
    def wants_item?(item)
      wants.where(item_id: item.id).any?
    end

    # Returns the user's existing want for +item+, or +nil+ if there isn't one.
    def want_for_item(item)
      wants.where(item_id: item.id).first
    end
  end
end
