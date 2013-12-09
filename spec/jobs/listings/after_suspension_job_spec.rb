require 'spec_helper'

describe Listings::AfterSuspensionJob do
  subject { Listings::AfterSuspensionJob }

  let(:listing) { stub_listing 'Disembodied eyeball' }

  describe "#hide_likes" do
    it 'enqueues Likes::HideLikeableLikesJob' do
      Likes::HideLikeableLikesJob.expects(:enqueue).with(:listing, listing.id)
      subject.hide_likes(listing)
    end
  end

  describe "#notify_seller_listing_suspended" do
    it 'injects ListingSuspended notification' do
      subject.expects(:inject_notification).
        with(:ListingSuspended, listing.seller_id, has_entry(listing_id: listing.id))
      subject.notify_seller_listing_suspended(listing)
    end
  end
end
