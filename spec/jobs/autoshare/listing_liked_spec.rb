require "spec_helper"

describe Autoshare::ListingLiked do
  let(:listing) { stub_listing 'Mars Maltesers 37g x 5 Pack', seller: stub_user('Matthew Sweet') }
  let(:listing_url) { 'http://clickety/click' }
  let(:liker) { stub_user 'Grant Lee Buffalo' }

  it "autoshares to the seller's networks when the listing is liked" do
    Listing.expects(:find).with(listing.id).returns(listing)
    User.expects(:find).with(liker.id).returns(liker)
    liker.expects(:autoshare).with(:listing_liked, listing, listing_url, is_a(Hash))
    Autoshare::ListingLiked.perform(listing.id, listing_url, liker.id)
  end

  it "does not propagate an exception" do
    Listing.expects(:find).raises(ActiveRecord::RecordNotFound)
    liker.expects(:autoshare).never
    expect { Autoshare::ListingLiked.perform(listing.id, listing_url, liker.id) }.not_to raise_error
  end
end
