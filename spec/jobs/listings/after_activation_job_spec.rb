require 'spec_helper'

describe Listings::AfterActivationJob do
  let(:listing) { FactoryGirl.create(:active_listing) }

  subject { Listings::AfterActivationJob }

  describe "#email_activated" do
    it "enqueues the job" do
      EmailListingActivated.expects(:enqueue).with(listing.id)
      subject.email_activated(listing)
    end
  end

  describe "#email_seller_welcome" do
    it "enqueues the job for the seller's first listing" do
      listing.seller.stubs(:seller_listings).returns([mock])
      subject.expects(:send_email).with(:seller_welcome, listing)
      subject.email_seller_welcome(listing)
    end

    it "does not enqueue the job when the seller has more than one listing" do
      listing.seller.stubs(:seller_listings).returns([mock, mock])
      subject.expects(:send_email).never
      subject.email_seller_welcome(listing)
    end
  end

  describe "#autoshare_activated" do
    it "enqueues the job" do
      listing_url = subject.url_helpers.listing_url(listing)
      Autoshare::ListingActivated.expects(:enqueue).with(listing.id, listing_url)
      subject.autoshare_activated(listing)
    end
  end

  describe "#facebook_activated" do
    it "posts a story to the ticker when allowed" do
      listing_url = subject.url_helpers.listing_url(listing)
      listing.seller.expects(:allow_autoshare?).with(:listing_activated, :facebook).returns(true)
      Facebook::OpenGraphListing.expects(:enqueue_at).
        # there are no user generated images since the listing's photo is not 480x480
        with(is_a(Time), listing.id, listing_url, listing.seller.id, :post, has_entry(user_generated_images: []))
      subject.facebook_activated(listing)
    end

    it "doesn't post a story to the ticker when disallowed" do
      listing.seller.expects(:allow_autoshare?).with(:listing_activated, :facebook).returns(false)
      Facebook::OpenGraphListing.expects(:enqueue_at).never
      subject.facebook_activated(listing)
    end
  end

  describe "#reveal_likes" do
    it 'enqueues Likes::RevealLikeableLikesJob' do
      Likes::RevealLikeableLikesJob.expects(:enqueue).with(:listing, listing.id)
      subject.reveal_likes(listing)
    end
  end

  describe '#update_mixpanel' do
    it 'should mark the seller as a lister' do
      listing.seller.expects(:mark_lister!)
      listing.seller.expects(:mixpanel_sync!)
      subject.update_mixpanel(listing)
    end

    context 'on first activation' do
      before do
        listing.seller.stubs(:mark_lister!)
        listing.seller.stubs(:mixpanel_sync!)
      end

      context 'of internal listing' do
        it 'increments listings_created and tracks internal listing publish' do
          listing.seller.expects(:mixpanel_increment!).with(:listings_created)
          subject.expects(:track_usage).with(is_a(Events::PublishListing))
          subject.update_mixpanel(listing, first_activation: true)
        end
      end

      context 'of external listing' do
        let(:listing) { FactoryGirl.create(:external_listing) }

        it 'increments listings_created and tracks external listing publish' do
          listing.seller.expects(:mixpanel_increment!).with(:listings_created)
          subject.expects(:track_usage).with(is_a(Events::PublishExternalListing))
          subject.update_mixpanel(listing, first_activation: true)
        end
      end
    end
  end
end
