require 'ladon'

module Users
  class DeleteInactiveStashesJob < Ladon::Job
    @queue = :users

    def self.work(seconds = 0)
      num_deleted = 0
      with_error_handling("Delete stashes for users inactive longer than #{seconds} seconds") do
        num_deleted = User.delete_inactive_stashes!(seconds)
      end
      num_deleted
    end
  end
end
