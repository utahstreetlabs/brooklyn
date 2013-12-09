require 'spec_helper'

describe Listings::AfterLikeJob do
  let(:liker) { stub_user 'Ted Greene' }
  let(:seller) { stub_user 'Wes Montgomery' }
  let(:like) { stub('like') }
  let(:listing) { stub_listing 'Chord Chemistry, Modern Chord Progressions: Jazz and Classical Voicings for Guitar', seller: seller }

  subject { Listings::AfterLikeJob }

  describe 'work' do
    let(:listing_id) { 1 }
    let(:liker_id) { 2 }
    let(:liker) { stub_user 'Kevin Bacon' }
    let(:listing) { stub_listing 'Bacon' }
    let(:previously_liked) { true }
    let(:like) { stub 'Kevin Bacon likes Bacon', tombstone: previously_liked }
    let(:job) { Listings::AfterLikeJob }
    subject { Listings::AfterLikeJob.work(listing_id, liker_id, nil) }
    before do
      Listing.expects(:find).with(listing_id).returns(listing)
      User.expects(:find).with(liker_id).returns(liker)
      Pyramid::User::Likes.expects(:get).with(liker_id, :listing, listing_id).returns(like)
    end

    describe 'when like is nil' do
      let(:like) { nil }
      it { should be_nil }
    end

    describe 'when like is not nil' do
      describe 'when not previously liked' do
        let(:previously_liked) { false }
        before do
          job.expects(:inject_like_story).with(listing, liker)
          job.expects(:post_like_to_facebook).with(listing, liker)
          job.expects(:post_like_notification_to_facebook).with(listing, liker)
          job.expects(:email_liked).with(listing, liker)
          job.expects(:autoshare_liked).with(listing, liker, {})
          job.expects(:notify_seller_liked).with(listing, liker)
        end

        it { should be_nil }
      end

      describe "when liker is the listing's seller and not previously liked" do
        let(:previously_liked) { false }
        let(:listing) { stub_listing 'Bacon', seller: liker }

        before do
          job.expects(:inject_like_story).with(listing, liker)
          job.expects(:post_like_to_facebook).with(listing, liker)
          job.expects(:email_liked).never
          job.expects(:autoshare_liked).never
          job.expects(:notify_seller_liked).never
        end

        it { should be_nil }
      end
    end
  end

  describe "#autoshare_liked" do
    it "enqueues the job" do
      listing_url = subject.url_helpers.listing_url(listing)
      Autoshare::ListingLiked.expects(:enqueue).with(listing.id, listing_url, liker.id, is_a(Hash))
      subject.autoshare_liked(listing, liker)
    end
  end

  describe '#inject_like_story' do
    it 'injects listing liked story' do
      subject.expects(:inject_listing_story).with(:listing_liked, liker.id, listing)
      subject.inject_like_story(listing, liker)
    end
  end

  describe "#email_liked" do
    it "enqueues the job" do
      seller.expects(:allow_email?).returns(true)
      subject.expects(:send_email).with(:liked, listing, liker.id)
      subject.email_liked(listing, liker)
    end

    it "doesn't enqueue the job if seller doesn't allow email" do
      seller.expects(:allow_email?).returns(false)
      subject.expects(:send_email).never
      subject.email_liked(listing, liker)
    end
  end

  describe "#post_like_to_facebook" do
    it "posts a story to the timeline when allowed" do
      listing_url = subject.url_helpers.listing_url(listing)
      liker.expects(:allow_autoshare?).with(:listing_liked, :facebook).returns(true)
      Facebook::OpenGraphListing.expects(:enqueue_at).with(is_a(Time), listing.id, listing_url, listing.seller.id,
        :love)
      subject.post_like_to_facebook(listing, liker)
    end

    it "doesn't post a story to the ticker when disallowed" do
      liker.expects(:allow_autoshare?).with(:listing_liked, :facebook).returns(false)
      Facebook::OpenGraphListing.expects(:enqueue_at).never
      subject.post_like_to_facebook(listing, liker)
    end
  end
end
