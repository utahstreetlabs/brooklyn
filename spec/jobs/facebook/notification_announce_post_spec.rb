require 'spec_helper'

describe Facebook::NotificationAnnouncePost do
  subject { Facebook::NotificationAnnouncePost }
  let(:user) { FactoryGirl.create(:registered_user, name: 'Miles Davis') }
  let(:profile) { FactoryGirl.create(:network_profile,
    name: "Miles Davis", id: 1, person_id: user.person_id, connection_count: 14) }
  let(:follower_profile1) { FactoryGirl.create(:network_profile,
    name: "Ron Carter", id: 2, uid: 5555, person_id: user.person_id) }
  let(:follower_profile2) { FactoryGirl.create(:network_profile,
    name: "Herbie Hancock", id: 2, uid: 5556, person_id: user.person_id) }

  describe '#perform' do
    before do
      Rubicon::FacebookProfile.expects(:find).with(profile.id, is_a(Hash)).returns(profile)
      User.expects(:find_by_person_id!).with(profile.person_id).returns(user)
      profile.expects(:followers).with(is_a(Hash)).returns([follower_profile1, follower_profile2])
      subject.expects(:notification_post).with(user, profile, [follower_profile1, follower_profile2])
    end

    it 'posts the notification successfully' do
      subject.perform(profile.id)
    end
  end

  describe 'notification_post' do
    let(:ref) { Network::Facebook.notification_announce_group }
    let(:href) { '/foo/bar' }
    let(:no_friend_template) { I18n.t('networks.facebook.notification.announce.no_friends.template') }
    let(:one_friend_template) { I18n.t('networks.facebook.notification.announce.one_friend.template',
      user_id: follower_profile1.uid) }
    let(:many_friends_one_template) { I18n.t('networks.facebook.notification.announce.many_friends.template',
      user_id_1: follower_profile1.uid, user_id_2: follower_profile2.uid, other_friends: '1 other friend')  }
    let(:many_friends_eighteen_template) { I18n.t('networks.facebook.notification.announce.many_friends.template',
      user_id_1: follower_profile1.uid, user_id_2: follower_profile2.uid, other_friends: '2 other friends') }

    before do
      subject.expects(:root_path).returns(href)
    end

    it 'posts the correct notification when user has no friends' do
      profile.stubs(:connection_count).returns(0)
      profile.expects(:post_notification).with({ template: no_friend_template, href: href, ref: ref })
      subject.notification_post(user, profile, [])
    end

    it 'posts the correct notification when user has one friend' do
      profile.stubs(:connection_count).returns(1)
      profile.expects(:post_notification).with({ template: one_friend_template, href: href, ref: ref })
      subject.notification_post(user, profile, [follower_profile1])
    end

    it 'posts the correct notification when user has two friends' do
      profile.stubs(:connection_count).returns(2)
      profile.expects(:post_notification).with({ template: one_friend_template, href: href, ref: ref })
      subject.notification_post(user, profile, [follower_profile1])
    end

    it 'posts the correct notification when user has three friends' do
      profile.stubs(:connection_count).returns(3)
      profile.expects(:post_notification).with({ template: many_friends_one_template, href: href, ref: ref })
      subject.notification_post(user, profile, [follower_profile1, follower_profile2])
    end

    it 'posts the correct notification when user has two or more friends' do
      profile.stubs(:connection_count).returns(20)
      profile.expects(:post_notification).with({ template: many_friends_eighteen_template, href: href, ref: ref })
      subject.notification_post(user, profile, [follower_profile1, follower_profile2])
    end
  end
end
