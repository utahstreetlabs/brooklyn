require 'spec_helper'

describe CollectionFollows::AfterCreatedJob do
  subject { CollectionFollows::AfterCreatedJob }

  describe '::inject_collection_follow_notification' do
    context 'when seller is collection owner' do
      it 'does not inject' do
        collection = FactoryGirl.create(:collection)
        follower = collection.owner
        subject.expects(:inject_notification).never
        subject.inject_collection_follow_notification(collection, follower)
      end
    end

    context 'when seller is not collection owner' do
      it 'injects' do
        collection = FactoryGirl.create(:collection)
        follower = FactoryGirl.create(:registered_user)
        subject.expects(:inject_notification)
        subject.inject_collection_follow_notification(collection, follower)
      end
    end
  end

  describe '::send_collection_follow_email' do
    context 'when seller is collection owner' do
      it 'does not send' do
        collection = FactoryGirl.create(:collection)
        follower = collection.owner
        subject.expects(:inject_email).never
        subject.send_collection_follow_email(collection, follower)
      end
    end

    context 'when seller is not collection owner' do
      it 'sends' do
        collection = FactoryGirl.create(:collection)
        follower = FactoryGirl.create(:registered_user)
        collection.owner.stubs(:allow_email?).returns(true)
        subject.expects(:send_email)
        subject.send_collection_follow_email(collection, follower)
      end
    end
  end

  describe '::update_mixpanel' do
    context 'when seller is collection owner' do
      it 'does not update' do
        collection = FactoryGirl.create(:collection)
        follower = collection.owner
        subject.expects(:track_usage).never
        subject.update_mixpanel(collection, follower)
      end
    end

    context 'when seller is not collection owner' do
      it 'updates' do
        collection = FactoryGirl.create(:collection)
        follower = FactoryGirl.create(:registered_user)
        subject.expects(:track_usage)
        subject.update_mixpanel(collection, follower)
      end
    end
  end
end
