require 'spec_helper'

describe Settings::NetworksController do
  describe "#show" do
    it_behaves_like "secured against anonymous users" do
      before { get :index }
    end

    context "for a logged-in user" do
      before { act_as_stub_user }

      it "shows the page" do
        get :index
        response.should render_template(:index)
      end
    end
  end

  describe "#update" do
    let(:id) { 'deadbeef' }
    let(:profile) { stub('profile') }

    it_behaves_like "secured against anonymous users" do
      before { click_save }
    end

    context "for a logged-in user" do
      let(:preferences) { stub('preferences') }
      let(:user) { act_as_stub_user }

      before do
        user.stubs(:preferences).returns(preferences)
        Rubicon::Profile.expects(:find).with(id).returns(profile)
        user.expects(:save_autoshare_prefs).returns(true)
        preferences.expects(:save_never_autoshare).with(false).returns(true)
      end

      it "saves autoshare prefs" do
        profile.stubs(:network).returns(:twitter)
        click_save
        response.should redirect_to(settings_networks_path)
        flash[:notice].should be
      end
    end

    def click_save
      params_hash = {id: id, user: {autoshare_prefs: {'listing_liked' => '1'}}}
      put :update, params_hash
    end
  end

  describe "#destroy" do
    let(:id) { 'deadbeef' }
    let(:identity) { stub('identity') }
    let(:profile) { stub('profile', network: 'facebook', uid: '1234', identity: identity) }

    it_behaves_like "secured against anonymous users" do
      before { click_button }
    end

    context "for a logged-in user" do
      before { act_as_stub_user }

      it "disconnects the profile" do
        Rubicon::Profile.expects(:find).with(id).returns(profile)
        Identity.expects(:find_by_provider_id).with(profile.network, profile.uid).returns(identity)
        identity.expects(:delete!)
        click_button
        response.should redirect_to(settings_networks_path)
        flash[:notice].should be
      end
    end

    def click_button
      delete :destroy, id: id
    end
  end

  describe "#allow_autoshare" do
    let(:network) { :facebook }
    let(:event) { :listing_activated }
    let(:preferences) { stub('preferences') }
    it_behaves_like "xhr secured against anonymous users" do
      before { click_allow_autoshare }
    end

    it "should call allow_autoshare! on the current user's preferences" do
      act_as_stub_user
      subject.current_user.expects(:preferences).returns(preferences)
      preferences.expects(:allow_autoshare!).with(network, event)
      click_allow_autoshare
      response.should be_jsend_success
    end

    def click_allow_autoshare
      xhr :put, :allow_autoshare, network: network, event: event, format: :json
    end
  end

  describe "#never_autoshare" do
    let(:network) { :facebook }
    let(:event) { :listing_activated }
    let(:preferences) { stub('preferences') }
    it_behaves_like "xhr secured against anonymous users" do
      before { click_never_autoshare }
    end

    context "with a logged in user" do
      before do
        act_as_stub_user
        subject.current_user.expects(:preferences).returns(preferences)
      end

      it "should set never_autoshare to true and return success" do
        preferences.expects(:save_never_autoshare).with(true).returns(true)
        click_never_autoshare
        response.should be_jsend_success
      end

      it "should set never_autoshare to false and return error" do
        preferences.expects(:save_never_autoshare).with(true).returns(false)
        click_never_autoshare
        response.should be_jsend_error
      end
    end

    def click_never_autoshare
      xhr :put, :never_autoshare, format: :json
    end
  end
end
