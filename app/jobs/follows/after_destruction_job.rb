require 'brooklyn/redhook'
require 'brooklyn/sprayer'
require 'ladon'

module Follows
  class AfterDestructionJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :follows

    class << self
      # this signature is not compatible with that of the earlier version of this job, so any jobs left in the queue
      # when this code is deployed will fail. on the other hand, those jobs are all failing now because the follow
      # no longer exists in the database by the time the job is performed. so, it's a wash.
      def work(follower_id, followee_id, options = {})
        with_error_handling("After destruction of follow between #{follower_id} and #{followee_id} with options #{options}",
                            options.merge(follower_id: follower_id, followee_id: followee_id)) do
          follower = User.find(follower_id)
          followee = User.find(followee_id)
          destroy_connection(follower, followee)
          track_usage(Events::UnfollowUser.new(follower, followee, follow_type: options[:follow_type]))
        end
      end

      def destroy_connection(follower, followee)
        Brooklyn::Redhook.async_destroy_connection(follower.person_id, followee.person_id, :usl_follower)
      end
    end
  end
end
