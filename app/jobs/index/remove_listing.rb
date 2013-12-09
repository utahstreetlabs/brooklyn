require 'ladon/job'

module Index
  class RemoveListing < Ladon::Job
    @queue = :index

    def self.work(listing_id)
      with_error_handling("remove listing from solr index", listing_id: listing_id) do
        Listing.find(listing_id).remove_from_index
        Sunspot.commit if Brooklyn::Application.config.search.commit_on_write
      end
    end
  end
end
