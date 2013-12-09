require 'brooklyn/sprayer'
require 'ladon'

module Users
  class AfterOnboardingJob < Ladon::Job
    @queue = :users

    class << self
      def work(id, options = {})
        user = User.find(id)
        (user.autofollowings + user.interest_followings).each { |f| f.post_to_facebook! }
      end
    end
  end
end
