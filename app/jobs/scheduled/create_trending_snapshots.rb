require 'ladon'

module Scheduled
  class CreateTrendingSnapshots < Ladon::Job
    @queue = :scheduled

    def self.work
      with_error_handling('Creating trending snapshots') do
        TrendingList.create_snapshot!(config.window, config.listing_count)
        TrendingList.truncate_snapshots!(config.active_snapshots)
      end
    end

    def self.config
      Brooklyn::Application.config.home.trending
    end
  end
end
