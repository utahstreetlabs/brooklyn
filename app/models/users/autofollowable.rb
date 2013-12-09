require 'active_support/concern'

module Users
  module Autofollowable
    extend ActiveSupport::Concern

    included do
      has_one :autofollow, class_name: 'UserAutofollow', dependent: :destroy
    end

    # Adds the user to the autofollow list.
    #
    # @raise ActiveRecord::RecordNotUnique if the user is already on the autofollow list
    def add_to_autofollow_list!
      logger.debug("Adding user #{id} to autofollow list")
      create_autofollow!
    end

    # Removes the user from the autofollow list. Does nothing if the user is not on the list.
    def remove_from_autofollow_list
      logger.debug("Removing user #{id} from autofollow list")
      self.autofollow = nil
    end

    def autofollowed?
      not autofollow.nil?
    end

    module ClassMethods
      # Returns the list of users that are auto-followed during signup.
      def autofollow_list
        UserAutofollow.by_position.includes(:user).map(&:user)
      end
    end
  end
end
