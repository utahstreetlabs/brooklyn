require "spec_helper"

describe Autoshare::ListingActivated do
  let(:listing) { stub_listing 'Unicorn Horns (24-pack)', seller: stub_user('Bjork') }
  let(:listing_url) { 'http://clickety/click' }

  it "autoshares to the seller's networks when the listing is activated" do
    Listing.expects(:find).with(listing.id).returns(listing)
    listing.seller.expects(:autoshare).with(:listing_activated, listing, listing_url)
    Autoshare::ListingActivated.perform(listing.id, listing_url)
  end

  it "does not propagate an exception" do
    Listing.expects(:find).raises(ActiveRecord::RecordNotFound)
    listing.seller.expects(:autoshare).never
    expect { Autoshare::ListingActivated.perform(listing.id, listing_url) }.not_to raise_error
  end
end
