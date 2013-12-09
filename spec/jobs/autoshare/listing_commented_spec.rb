require "spec_helper"

describe Autoshare::ListingCommented do
  let(:listing) { stub_listing 'Cocaine, 1kg', seller: stub_user('Axl Rose') }
  let(:listing_url) { 'http://clickety/click' }
  let(:commenter) { stub_user 'Nikki Sixx' }
  let(:comment_text) { 'Dibs!' }

  it "autoshares to the seller's networks when the listing is commented upon" do
    Listing.expects(:find).with(listing.id).returns(listing)
    User.expects(:find).with(commenter.id).returns(commenter)
    commenter.expects(:autoshare).with(:listing_commented, listing, listing_url, comment_text)
    Autoshare::ListingCommented.perform(listing.id, listing_url, commenter.id, comment_text)
  end

  it "does not propagate an exception" do
    Listing.expects(:find).raises(ActiveRecord::RecordNotFound)
    commenter.expects(:autoshare).never
    Autoshare::ListingCommented.expects(:facebook_commented).never
    expect { Autoshare::ListingCommented.perform(listing.id, listing_url, commenter.id, comment_text) }.not_to raise_error
  end
end
