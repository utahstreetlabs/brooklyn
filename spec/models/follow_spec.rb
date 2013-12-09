require 'spec_helper'

describe Follow do
  describe 'after create' do
    subject { FactoryGirl.build(:follow) }

    it 'enqueues Follows::AfterCreationJob' do
      source = 'feed'
      Follows::AfterCreationJob.expects(:enqueue).with(is_a(Integer), has_entry(notify_followee: true))
      subject.save!
    end

    context 'when suppressing followee notifications' do
      before { subject.suppress_followee_notifications = true }
      it 'enqueues Follows::AfterCreationJob and does not notify followees' do
        Follows::AfterCreationJob.expects(:enqueue).with(is_a(Integer), has_entry(notify_followee: false))
        subject.save!
      end
    end
  end

  describe 'after destroy' do
    subject { FactoryGirl.create(:follow) }

    it 'enqueues Follows::AfterDestructionJob' do
      source = 'feed'
      Follows::AfterDestructionJob.expects(:enqueue).
        with(subject.follower_id, subject.user_id, follow_type: subject.class.name)
      subject.destroy
    end
  end

  describe "saving" do
    let(:follow) { FactoryGirl.create(:follow) }
    let(:duplicate) { follow.dup }

    context "#save" do
      it "enforces uniqueness at the db level" do
        duplicate.save.should be_false
        duplicate.errors[:user].should_not be_empty
        duplicate.errors[:follower].should_not be_empty
      end
    end

    context "#save!" do
      it "raises RecordNotSaved" do
        expect { duplicate.save! }.to raise_exception(ActiveRecord::RecordNotSaved)
      end
    end
  end

  describe "#refollow?" do
    it "is a refollow when a follow tombstone exists" do
      follow = FactoryGirl.create(:follow)
      FactoryGirl.create(:follow_tombstone, user: follow.user, follower: follow.follower)
      follow.refollow?.should be_true
    end

    it "is not a refollow when a follow tombstone does not exist" do
      follow = FactoryGirl.create(:follow)
      follow.refollow?.should be_false
    end
  end

  describe '#post_to_facebook!' do
    subject { FactoryGirl.build(:follow) }
    let(:allow_autoshare) { true }
    before { subject.follower.stubs(:allow_autoshare?).with(:user_followed, :facebook).returns(allow_autoshare) }

    it 'enqueues Facebook::OpenGraphUser job' do
      Facebook::OpenGraphFollow.expects(:enqueue).with(subject.id)
      subject.post_to_facebook!
    end

    context 'when follower does not allow autosharing' do
    let(:allow_autoshare) { false }
      it 'does not enqueue the job' do
        Facebook::OpenGraphFollow.expects(:enqueue).never
        subject.post_to_facebook!
      end
    end
  end

  describe '#post_notification_to_facebook!' do
    subject { FactoryGirl.build(:follow) }

    it 'enqueues Facebook::NotificationFollow job' do
      Facebook::NotificationFollow.expects(:enqueue).with(subject.id)
      subject.post_notification_to_facebook!
    end
  end
end
