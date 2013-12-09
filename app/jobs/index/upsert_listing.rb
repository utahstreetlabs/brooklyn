require 'ladon/job'

module Index
  class UpsertListing < Ladon::Job
    @queue = :index

    def self.work(listing_id)
      with_error_handling("insert / update listing in solr index", listing_id: listing_id) do
        Listing.find(listing_id).index
        Sunspot.commit if Brooklyn::Application.config.search.commit_on_write
      end
    end
  end
end
