require 'spec_helper'

describe Settings::Networks::FacebookController do
  describe "#disable_timeline" do
    it_behaves_like "xhr secured against anonymous users" do
      before { click_disable_timeline }
    end

    context "for a logged-in user" do
      before { act_as_stub_user }

      it "should call save_features_disabled_prefs on the current user's preferences" do
        subject.current_user.expects(:allow_feature?).with(:request_timeline_facebook).returns(true)
        subject.current_user.expects(:save_features_disabled_prefs).returns(true)
        click_disable_timeline
        response.should be_jsend_success
      end
    end

    def click_disable_timeline
      xhr :put, :disable_timeline, format: :json
    end
  end

  describe "#timeline_permission" do
    let(:profile) { stub('profile') }
    let(:id) { 'deadbeef' }

    it_behaves_like "secured against anonymous users" do
      before { click_timeline_permission }
    end

    context "for a logged-in user" do
      before do
        act_as_stub_user
        Rubicon::Profile.expects(:find).with(id).returns(profile)
      end

      it "should render success when permissions missing" do
        profile.expects(:missing_live_permissions).with([:publish_actions]).returns([:publish_actions])
        click_timeline_permission
        response.should be_jsend_success
        response.jsend_data['missing'].should == true
      end

      it "should render success when permissions not missing" do
        profile.expects(:missing_live_permissions).with([:publish_actions]).returns([])
        click_timeline_permission
        response.should be_jsend_success
        response.jsend_data['missing'].should == false
      end

      it "should render error on exception" do
        profile.expects(:missing_live_permissions).with([:publish_actions]).raises(Exception)
        click_timeline_permission
        response.should be_jsend_error
      end
    end

    def click_timeline_permission
      params_hash = {id: id}
      put :timeline_permission, params_hash, format: :json
    end
  end
end
