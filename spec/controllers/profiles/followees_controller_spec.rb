require 'spec_helper'

describe Profiles::FolloweesController do
  let(:profile_user) { stub_user('Trevor Dunn') }
  let(:followee) { stub_user('Roddy Bottum', registered_followers: [stub_user('Mike Patton')]) }

  before do
    User.stubs(:find_by_slug!).with(profile_user.slug).returns(profile_user)
    User.stubs(:find_by_slug!).with(followee.slug).returns(followee)
  end

  describe "#update" do
    it_behaves_like 'xhr secured against anonymous users' do
      before { do_update }
    end

    context "for a logged-in user" do
      include_context "for a logged-in user"

      it 'should follow the followee' do
        subject.current_user.expects(:follow!).with(followee)
        do_update
        response.should be_jsend_success
        response.jsend_data['button'].should be
        response.jsend_data['followersCount'].should == followee.registered_followers.count
        response.jsend_data['following'].should == true
      end
    end

    def do_update
      xhr :put, :update, format: :json, public_profile_id: profile_user.slug, id: followee.slug
    end
  end

  describe "#destroy" do
    it_behaves_like 'xhr secured against anonymous users' do
      before { do_destroy }
    end

    context "for a logged-in user" do
      include_context "for a logged-in user"

      it 'should unfollow the followee' do
        subject.current_user.expects(:unfollow!).with(followee)
        do_destroy
        response.should be_jsend_success
        response.jsend_data['button'].should be
        response.jsend_data['followersCount'].should == followee.registered_followers.count
        response.jsend_data['following'].should == false
      end
    end

    def do_destroy
      xhr :delete, :destroy, format: :json, public_profile_id: profile_user.slug, id: followee.slug
    end
  end
end
