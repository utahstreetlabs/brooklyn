require 'spec_helper'

describe Facebook::FollowRegisteredFriends do
  subject { Facebook::FollowRegisteredFriends }
  context "when scheduled for a user" do
    let(:user_id) { 1 }

    it "does nothing when the user does not exist" do
      User.expects(:with_person).with(user_id).returns(nil)
      subject.perform(user_id)
    end

    context "when the user exists" do
      let(:person) { stub('person') }
      let(:user) { stub(id: user_id, person: person) }
      before do
        User.expects(:with_person).with(user_id).returns(user)
      end

      it "raises a 'not-ready' exception when the user is not registered" do
        user.expects(:registered?).returns(false)
        person.expects(:for_network).never
        user.expects(:follow_registered_network_followers!).never
        expect { subject.perform(user_id) }.to raise_error(FacebookAutoFollowNotReadyException)
      end

      context "when the user is registered" do
        before { user.expects(:registered?).returns(true) }

        it "raises a 'not-ready' exception when the user does not have a profile" do
          person.expects(:for_network).with(:facebook).returns(nil)
          user.expects(:follow_registered_network_followers!).never
          expect { subject.perform(user_id) }.to raise_error(FacebookAutoFollowNotReadyException)
        end

        it "raises a 'not-ready' exception when the user has an unsynced profile" do
          profile = stub(synced?: false)
          person.expects(:for_network).with(:facebook).returns(profile)
          user.expects(:follow_registered_network_followers!).never
          expect { subject.perform(user_id) }.to raise_error(FacebookAutoFollowNotReadyException)
        end

        it "follows its Facebook friends when the user has a synced profile" do
          profile = stub(synced?: true)
          person.expects(:for_network).with(:facebook).returns(profile)
          user.expects(:follow_registered_network_followers!).with(profile)
          user.expects(:follow_inviters!).with(profile)
          subject.perform(user_id)
        end
      end
    end
  end
end
