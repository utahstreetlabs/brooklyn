require 'spec_helper'

describe Follows::AfterCreationJob do
  let(:follower) do
    stub_user 'Lisbeth Salander', id: 123, person_id: 123, directly_invited_by?: false, allow_autoshare?: true
  end
  let(:followee) do
    stub_user 'Mikael Blomkvist', id: 456, person_id: 456, allow_email?: true
  end
  let(:follow) do
    stub('follow', id: 789, follower: follower, follower_id: follower.id, followee: followee, user_id: followee.id,
      refollow?: false)
  end

  subject { Follows::AfterCreationJob }

  describe '#send_user_follow_email' do
    it 'sends :follow email' do
      subject.expects(:send_email).with(:follow, follow)
      subject.send_user_follow_email(follow, notify_followee: true)
    end

    context 'when the follow is a refollow' do
      before { follow.stubs(:refollow?).returns(true) }

      it 'does not send the email by default' do
        subject.expects(:send_email).never
        subject.send_user_follow_email(follow, notify_followee: true)
      end

      it 'does not send the email when refollows are not acceptable' do
        subject.expects(:send_email).never
        subject.send_user_follow_email(follow, notify_followee: true, refollow: false)
      end

      it 'sends the email when refollows are acceptable' do
        subject.expects(:send_email).with(:follow, follow)
        subject.send_user_follow_email(follow, notify_followee: true, refollow: true)
      end
    end

    context 'when the follower was invited by the followee' do
      before { follower.stubs(:directly_invited_by?).with(followee).returns(true) }
      it 'does not send the email' do
        subject.expects(:send_email).never
        subject.send_user_follow_email(follow, notify_followee: true)
      end
    end

    context 'when the followee does not allow the email' do
      before { followee.stubs(:allow_email?).with(:follow_me).returns(false) }
      it 'does not send the email' do
        subject.expects(:send_email).never
        subject.send_user_follow_email(follow, notify_followee: true)
      end
    end

    context 'when the follow should not generate notifications' do
      it 'does not send the email' do
        subject.expects(:send_email).never
        subject.send_user_follow_email(follow, notify_followee: false)
      end
    end
  end

  describe '#inject_user_follow_notification' do
    it 'injects :Follow notification' do
      subject.expects(:inject_notification).with(:Follow, followee.id, has_entry(follower_id: follower.id))
      subject.inject_user_follow_notification(follow, notify_followee: true)
    end

    context 'when the follow is a refollow' do
      before { follow.stubs(:refollow?).returns(true) }
      it 'does not inject the notification' do
        subject.expects(:inject_notification).never
        subject.inject_user_follow_notification(follow, notify_followee: true)
      end
    end

    context 'when the follow should not generate notifications' do
      it 'does not inject the notification' do
        subject.expects(:inject_notification).never
        subject.inject_user_follow_notification(follow, notify_followee: false)
      end
    end
  end

  describe '#autoshare_user_follow' do
    it 'injects Autoshare::UserFollowed job' do
      Autoshare::UserFollowed.expects(:enqueue).with(followee.id, is_a(String), follower.id)
      subject.autoshare_user_follow(follow)
    end

    context 'when the follow is a refollow' do
      before { follow.stubs(:refollow?).returns(true) }
      it 'does not inject the job' do
        Autoshare::UserFollowed.expects(:enqueue).never
        subject.autoshare_user_follow(follow)
      end
    end
  end

  describe '#create_connection' do
    it 'enqueues the job' do
      Brooklyn::Redhook.expects(:async_create_connection).with(follower.person_id, followee.person_id, :usl_follower)
      subject.create_connection(follow)
    end
  end

  describe '#post_user_follow_to_facebook' do
    it 'enqueues Facebook::OpenGraphUser job' do
      follow.expects(:post_to_facebook!).once
      subject.post_user_follow_to_facebook(follow)
    end

    context 'when followee notifications are disabled' do
      it 'does not enqueue the job' do
        follow.expects(:post_to_facebook!).never
        subject.post_user_follow_to_facebook(follow, suppress_fb_follow: true)
      end
    end
  end

  describe '#update_mixpanel' do
    it 'should increment mixpanel follows' do
      follower.expects(:mixpanel_increment!).with(:follows)
      subject.update_mixpanel(follow)
    end
  end
end
