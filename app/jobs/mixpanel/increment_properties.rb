require 'ladon'

module Mixpanel
  class IncrementProperties < Ladon::Job
    @queue = :tracking

    def self.work(user_id, params)
      Brooklyn::Mixpanel.increment(User.find(user_id).visitor_id, params)
    end
  end
end
