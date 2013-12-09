require 'brooklyn/sprayer'
require 'ladon'

module Users
  class AfterNetworkSyncJob < Ladon::Job
    include Brooklyn::Sprayer
    @queue = :users

    def self.work(person_id, network, options = {})
      person = Person.find(person_id)
      user = person.user
      profile = person.for_network(network)
      user.mixpanel_set!("#{network}_follows" => profile.api_follows_count)
    end
  end
end
