module Profiles
  # XXX: this job should eventually be processed directly by mendocino, but until mendocino handles all networks, it's
  # overly complicated, so we'll use the network queue and then split during work
  class SyncEach < Ladon::Job
    @queue = :network

    def self.work(person_id)
      if person = Person.find(person_id)
        person.connected_profiles.each do |profile|
          profile.async_sync
        end
      end
    end

    def self.include_ladon_context?
      false
    end
  end
end

