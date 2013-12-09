require 'resque'

module Profiles
  class SyncBase < Ladon::Job
    def self.queue
      :profiles
    end

    def self.mendocino_syncable?(network)
      Brooklyn::Application.config.networks.mendocino_syncable.include?(network)
    end

    def self.enqueue(person_id, uid, network)
      if mendocino_syncable?(network)
        super
      else
        self.rubicon_class.enqueue(person_id, network)
      end
    end

    def self.work(person_id, uid, network); end

    def self.include_ladon_context?
      false
    end
  end
end
