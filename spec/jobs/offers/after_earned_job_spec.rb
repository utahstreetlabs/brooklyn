require 'spec_helper'

describe Offers::AfterEarnedJob do
  subject { Offers::AfterEarnedJob }

  let(:earner) { stub_user 'earner' }
  let(:offer) { stub_offer 'free cats' }

  describe '#work' do
    before do
      Offer.expects(:find).with(offer.id).returns(offer)
      User.expects(:find).with(earner.id).returns(earner)
    end

    it "tracks the offer" do
      subject.stubs(:post_to_feed)
      subject.expects(:track_usage).with(kind_of(Events::OfferEarn))
      subject.work(offer.id, earner.id)
    end

    describe 'facebook posting' do
      let(:facebook_profile) { earner.person.for_network(:facebook) }
      let(:autoshare_allowed) { true }
      let(:connected) { true }
      before do
        subject.stubs(:track_usage)
        earner.stubs(:allow_autoshare?).with(:offer_earned, :facebook).returns(autoshare_allowed)
        facebook_profile.stubs(:connected?).returns(connected)
      end

      describe 'when autoshare allowed and profile is connected' do
        it "posts to facebook" do
          facebook_profile.expects(:post_to_feed).
            with(name: offer.fb_story_name, caption: offer.fb_story_caption,
                 description: offer.fb_story_description, picture: offer.fb_story_image.url,
                 link: Brooklyn::Application.routes.url_helpers.offer_url(offer))
          subject.work(offer.id, earner.id)
        end
      end

      describe 'when autoshare is not allowed' do
        let(:autoshare_allowed) { false }
        it "doesn't post to facebook" do
          facebook_profile.expects(:post_to_feed).never
          subject.work(offer.id, earner.id)
        end
      end

      describe 'when the profile is not connected' do
        let(:connected) { false }
        it "doesn't post to facebook" do
          facebook_profile.expects(:post_to_feed).never
          subject.work(offer.id, earner.id)
        end
      end
    end
  end
end
