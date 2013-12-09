require 'spec_helper'

describe ListingCollectionAttachments::AfterDestroyedJob do
  subject { ListingCollectionAttachments::AfterDestroyedJob }

  let(:listing) { stub_listing 'Nasty dreads', seller: stub_user('Corey Glover') }

  it "evicts a listing from a user's recent listings cache" do
    listing.seller.recent_saved_listing_ids << listing.id
    subject.evict_listing_from_recent_cache(listing)
    listing.seller.recent_saved_listing_ids.should be_empty
  end
end
