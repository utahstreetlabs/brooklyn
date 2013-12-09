require 'spec_helper'

describe Facebook::NotificationFollow do
  subject { Facebook::NotificationFollow }
  let(:follower) { stub_user('Dizzy Reed') }
  let(:followee) { stub_user('Tommy Stinson ') }

  describe '#perform' do
    let(:follow_id) { 1 }
    let(:profile) { '1234' }
    let(:follow) { stub('follow', user: followee, follower: follower) }

    before do
      Follow.expects(:find).with(follow_id).returns(follow)
      subject.expects(:notification_post).with(follower, followee)
    end

    it 'posts the notification successfully' do
      subject.perform(follow_id)
    end
  end

  describe 'notification_post' do
    let(:profile_url) { 'http://clackety/clack' }
    let(:fb_uid) { 6666 }
    let(:ref) { Brooklyn::Application.config.networks.facebook.notification.follow.ref }
    let(:href) { "/profiles/charlie-christian" }
    let(:follower_profile) { stub('profile', name: "Charlie Christian", id: 5555, uid: fb_uid) }
    let(:followee_profile) { stub('profile', name: "Dave Brubeck", id: 5556, uid: fb_uid) }

    it 'posts the notification' do
      follower.person.expects(:for_network).with(:facebook).returns(follower_profile)
      followee.person.expects(:for_network).with(:facebook).returns(followee_profile)
      followee_profile.expects(:followed_by?).returns(true)

      subject.expects(:profile_path).returns(href)
      followee_profile.expects(:post_notification).with(has_entries(template: is_a(String), href: href, ref: ref))
      subject.notification_post(follower, followee)
    end

    it 'does not post if the two users are not Facebook friends' do
      follower.person.expects(:for_network).with(:facebook).returns(follower_profile)
      followee.person.expects(:for_network).with(:facebook).returns(followee_profile)
      followee_profile.expects(:followed_by?).returns(false)
      followee_profile.expects(:post_notification).never
      subject.notification_post(follower, followee)
    end

    it 'does not post if there is no facebook profile for this followee' do
      followee_profile.expects(:post_notification).never
      followee.person.expects(:for_network).with(:facebook).returns(nil)
      subject.notification_post(follower, followee)
    end

    it 'does not post if there is no facebook profile for this followee' do
      followee_profile.expects(:post_notification).never
      followee.person.expects(:for_network).with(:facebook).returns(nil)
      subject.notification_post(follower, followee)
    end

    it 'does not post if there is no facebook profile for this follower' do
      followee_profile.expects(:post_notification).never
      follower.person.expects(:for_network).with(:facebook).returns(nil)
      subject.notification_post(follower, followee)
    end

    it 'catches exceptions raised from mogli' do
      follower.person.expects(:for_network).with(:facebook).returns(follower_profile)
      followee.person.expects(:for_network).with(:facebook).returns(followee_profile)
      followee_profile.expects(:followed_by?).returns(true)
      subject.expects(:profile_path).returns(href)
      followee_profile.expects(:post_notification).raises('Boom!')
      expect { subject.notification_post(follower, followee) }.not_to raise_error
    end
  end
end
