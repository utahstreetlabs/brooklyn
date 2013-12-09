require 'brooklyn/sprayer'
require 'ladon'

module Users
  class AfterConnectionJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :users

    class << self
      def work(id, options = {})
        with_error_handling("After connection of user #{id}") do
          user = User.find(id)
          import_profile_photo(user)
          import_location(user)
        end
      end

      def import_profile_photo(user)
        user.async_set_profile_photo_from_network
      end

      def import_location(user)
        user.async_set_location_from_network
      end
    end
  end
end
