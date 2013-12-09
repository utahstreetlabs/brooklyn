require 'ladon'

module Scheduled
  class CreateFeatureSnapshots < Ladon::Job
    @queue = :scheduled

    def self.work
      with_error_handling('Creating feature snapshots') do
        FeatureList.all.each do |list|
          list.create_snapshot!(config.window, config.listing_count)
          list.truncate_snapshots!(config.active_snapshots)
        end
      end
    end

    def self.config
      Brooklyn::Application.config.home.featured
    end
  end
end
