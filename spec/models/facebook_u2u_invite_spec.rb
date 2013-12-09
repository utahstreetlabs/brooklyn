require 'spec_helper'

describe FacebookU2uInvite do
  describe 'after create' do
    it 'enqueues after creation job' do
      Facebook::AfterU2uInviteCreationJob.expects(:enqueue).with(is_a(Integer))
      FactoryGirl.create(:facebook_u2u_invite)
    end
  end

  describe 'after update' do
    it 'does not enqueue after creation job' do
      u2u = FactoryGirl.create(:facebook_u2u_invite)
      Facebook::AfterU2uInviteCreationJob.expects(:enqueue).never
      u2u.update_attribute(:user_id, 123)
    end
  end

  describe 'after destroy' do
    subject { FactoryGirl.create(:facebook_u2u_invite) }

    it 'deletes the associated app request in FB' do
      subject.expects(:delete_app_request!)
      subject.destroy
    end

    it 'does not fail in the face of an error deleting the app request' do
      subject.expects(:delete_app_request!).raises("Boom!")
      expect { subject.destroy }.to_not raise_error
    end
  end

  describe '#find_all_pending' do
    it 'excludes completed invites' do
      i1 = FactoryGirl.create(:facebook_u2u_invite)
      i2 = FactoryGirl.create(:completed_facebook_u2u_invite)
      FacebookU2uInvite.find_all_pending.should == [i1]
    end

    it "limits to invites for a particular user" do
      i1 = FactoryGirl.create(:facebook_u2u_invite)
      i2 = FactoryGirl.create(:facebook_u2u_invite)
      FacebookU2uInvite.find_all_pending(i1.fb_user_id).should == [i1]
    end
  end

  describe '#find_all_pending_since' do
    it 'excludes completed invites' do
      i1 = FactoryGirl.create(:facebook_u2u_invite)
      i2 = FactoryGirl.create(:completed_facebook_u2u_invite)
      FacebookU2uInvite.find_all_pending_since(1.day.ago).should == [i1]
    end

    it 'excludes old invites' do
      i1 = FactoryGirl.create(:facebook_u2u_invite)
      Timecop.travel(2.days.ago) do
        i2 = FactoryGirl.create(:facebook_u2u_invite)
      end
      FacebookU2uInvite.find_all_pending_since(1.day.ago).should == [i1]
    end

    it 'limits to invites sent by a particular user' do
      i1 = FactoryGirl.create(:facebook_u2u_invite)
      i2 = FactoryGirl.create(:facebook_u2u_invite)
      i2.update_attribute(:created_at, 2.days.ago)
      FacebookU2uInvite.find_all_pending_since(1.day.ago, sender: i1.request.user).should == [i1]
    end
  end

  describe '#find_all_fb_user_ids_pending_since' do
    it 'succeeds' do
      i1 = FactoryGirl.create(:facebook_u2u_invite)
      i2 = FactoryGirl.create(:facebook_u2u_invite)
      uids = FacebookU2uInvite.find_all_fb_user_ids_pending_since(1.day.ago)
      uids.should have(2).entries
      uids.should include(i1.fb_user_id, i2.fb_user_id)
    end
  end

  describe '#count_complete' do
    it 'ignores pending invites' do
      i1 = FactoryGirl.create(:facebook_u2u_invite)
      i2 = FactoryGirl.create(:completed_facebook_u2u_invite)
      FacebookU2uInvite.count_complete.should == 1
    end

    it 'limits to invites sent by a particular user' do
      i1 = FactoryGirl.create(:completed_facebook_u2u_invite)
      i2 = FactoryGirl.create(:completed_facebook_u2u_invite)
      FacebookU2uInvite.count_complete(sender: i1.request.user).should == 1
    end
  end
end
