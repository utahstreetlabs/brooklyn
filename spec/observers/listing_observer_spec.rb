require 'spec_helper'

describe ListingObserver do
  let(:listing) { stub_listing 'Antique pick axe mining tool coal, silver', seller: stub_user('Crackity Jonez'), approved?: true }
  let(:listing_url) { ListingObserver.url_helpers.listing_url(listing) }

  subject { ListingObserver.instance }

  it "adds a listing to a user's recent listings cache" do
    subject.add_listing_to_recent_cache(listing, listing.seller)
    listing.seller.recent_listing_ids.should == [listing.id]
  end

  it "does not add a listing to a user's recent listings cache when the listing is already cached" do
    listing.seller.recent_listing_ids << listing.id
    subject.add_listing_to_recent_cache(listing, listing.seller)
    listing.seller.recent_listing_ids.should == [listing.id]
  end

  it "evicts a listing from a user's recent listings cache" do
    listing.seller.recent_listing_ids << listing.id
    subject.evict_listing_from_recent_cache(listing, listing.seller)
    listing.seller.recent_listing_ids.should be_empty
  end
end
