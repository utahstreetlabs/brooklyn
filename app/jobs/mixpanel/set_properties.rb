require 'ladon'

module Mixpanel
  class SetProperties < Ladon::Job
    @queue = :tracking

    def self.work(user_id, params)
      Brooklyn::Mixpanel.set(User.find(user_id).visitor_id, params)
    end
  end
end
