require "resque"
require 'ladon'

class SyncListings < Ladon::Job
  @queue = :sellers

  def self.work
    InternalListing.sync_all_sources
  rescue Exception => e
    Rails.logger.error("error syncing listings: #{e}")
    Airbrake.notify(
     :error_class => "Error syncing listings from remote sources",
     :error_message => "Error syncing listings from remote sources: #{e.message}",
     :params => {}
    )
    # re-raise for resque's sake
    raise
  end
end
