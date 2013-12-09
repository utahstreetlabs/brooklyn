require 'spec_helper'

describe Facebook::OpenGraphFollow do
  subject { Facebook::OpenGraphFollow }
  let(:follower) { stub_user('Dizzy Reed') }
  let(:followee) { stub_user('Tommy Stinson ') }

  describe '#perform' do
    let(:follow_id) { 1 }
    let(:fb_og_profile) { '1234' }
    let(:subscription_id) { '1234' }
    let(:add_response) { Mogli::Post.new(id: subscription_id) }
    let(:follow) { stub('follow', user: followee, follower: follower) }

    before do
      Follow.expects(:find).with(follow_id).returns(follow)
      subject.expects(:open_graph_post).with(follower, followee).returns(add_response)
    end

    it 'updates the fb_subscription_id of the follow' do
      follow.expects(:update_attribute).with(:fb_subscription_id, subscription_id)
      subject.perform(follow_id)
    end
  end

  describe 'helper methods' do
    let(:profile_url) { 'http://clackety/clack' }
    let(:fb_uid) { 6666 }
    let(:profile) { stub('profile', id: 5555, uid: fb_uid) }

    before do
      follower.person.expects(:for_network).with(:facebook).returns(profile)
    end

    describe '#fb_og_profile' do
      it 'returns the profile uid' do
        subject.fb_og_profile(follower).should == fb_uid
      end

      context 'when there is no facebook profile associated with the follower' do
        let(:profile) { nil }
        it 'returns the copious profile url' do
          subject.fb_og_profile(follower).should == subject.url_helpers.public_profile_url(follower)
        end
      end
    end

    describe '#open_graph_post' do
      before do
        subject.stubs(:fb_og_profile).with(followee).returns(profile_url)
      end

      let(:post_to_ticker_result) { {oh: :yeah} }
      it 'posts to the facebook timeline' do
        profile.expects(:og_postable?).returns(true)
        profile.expects(:post_to_ticker).with(has_entries(namespace: :og, action: :follows, profile: profile_url, params: has_entries(ref: regexp_matches(/profile:follow/)))).
          returns(post_to_ticker_result)
        subject.open_graph_post(follower, followee).should == post_to_ticker_result
      end

      it 'does not post if open graph is not allowed' do
        profile.expects(:og_postable?).returns(false)
        profile.expects(:post_to_ticker).never
        subject.open_graph_post(follower, followee)
      end

      context 'when there is no facebook profile associated with the follower' do
        let(:profile) { nil }
        it 'does not post' do
          profile.expects(:og_postable?).never
          profile.expects(:post_to_ticker).never
          subject.open_graph_post(follower, followee)
        end
      end

      it 'catches exceptions raised from og posts' do
        profile.expects(:og_postable?).returns(true)
        profile.expects(:post_to_ticker).raises('Boom!')
        expect { subject.open_graph_post(follower, followee) }.not_to raise_error
      end
    end
  end
end
