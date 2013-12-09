require 'spec_helper'

describe Settings::FeatureController do
  describe "#update_prefs" do
    let(:user_params) { {'feature_prefs' => {'request_timeline_facebook' => '1'}} }

    it_behaves_like "secured against anonymous users" do
      before { submit_prefs }
    end

    context "for a logged-in user" do
      let(:user) { act_as_stub_user }

      it "saves the features disabled prefs" do
        user.expects(:save_features_disabled_prefs).with(user_params['feature_prefs'])
        submit_prefs
        response.should be_jsend_success
      end

      it "returns a jsend error on exception" do
        user.expects(:save_features_disabled_prefs).with(user_params['feature_prefs']).raises(Exception)
        submit_prefs
        response.should be_jsend_error
      end
    end

    def submit_prefs
      put :update_prefs, user: user_params
    end
  end
end
