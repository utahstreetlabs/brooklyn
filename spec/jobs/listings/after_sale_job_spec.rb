require 'spec_helper'

describe Listings::AfterSaleJob do
  let(:buyer) { stub_user 'John McEnroe' }
  let(:listing) { stub_listing 'Can of tennis balls', buyer_id: buyer.id }

  subject { Listings::AfterSaleJob }

  describe '#inject_sale_story' do
    it 'injects listing sold story' do
      subject.expects(:inject_listing_story).
        with(:listing_sold, listing.seller_id, listing, has_entry(buyer_id: listing.buyer_id))
      subject.inject_sale_story(listing)
    end
  end

  describe '#post_sale_to_facebook' do
    it 'schedules Facebook::OpenGraphListing job when seller allows autosharing' do
      listing_url = subject.url_helpers.listing_url(listing)
      listing.seller.stubs(:allow_autoshare?).with(:listing_sold, :facebook).returns(true)
      Facebook::OpenGraphListing.expects(:enqueue_at).with(is_a(Time), listing.id, listing_url, listing.seller.id,
        :sell, user_generated_images: listing.photos.map {|p| p.file.url})
      subject.post_sale_to_facebook(listing)
    end

    it 'does not schedule Facebook::OpenGraphListing job when seller does not allow autosharing' do
      listing.seller.stubs(:allow_autoshare?).with(:listing_sold, :facebook).returns(false)
      Facebook::OpenGraphListing.expects(:enqueue_at).never
      subject.post_sale_to_facebook(listing)
    end
  end

  describe "#reveal_likes" do
    it 'enqueues Likes::RevealLikeableLikesJob' do
      Likes::RevealLikeableLikesJob.expects(:enqueue).with(:listing, listing.id)
      subject.reveal_likes(listing)
    end
  end
end
