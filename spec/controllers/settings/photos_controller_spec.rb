require 'spec_helper'

describe Settings::PhotosController do
  describe "#update" do
    let(:file) { fixture_file_upload('hamburgler.jpg', 'image/jpg') }

    it_behaves_like "xhr secured against anonymous users" do
      before { submit_photo_form }
    end

    context "for a logged-in user" do
      let(:user) { act_as_stub_user }

      context "updating profile photo" do
        before do
          user.expects(:profile_photo=).with(file)
        end

        it "should return jsend success if save succeeds" do
          user.expects(:save).returns(true)
          submit_photo_form
          response.should be_jsend_success
        end

        it "should return jsend errors if save fails" do
          user.expects(:save).returns(false)
          user.expects(:errors).returns({})
          submit_photo_form
          response.should be_jsend_error
        end
      end
    end

    def submit_photo_form
      xhr :put, :update, {user: {profile_photo: file}}.stringify_keys!.merge(format: :json)
    end
  end

  describe "#create" do
    let(:file) { fixture_file_upload('hamburgler.jpg', 'image/jpg') }
    let(:network) { :facebook }

    it_behaves_like "xhr secured against anonymous users" do
      before { submit_photo_form }
    end

    context "for a logged-in user" do
      let(:profile_photo) { stub('profile_photo') }
      let(:user) { act_as_stub_user(stubs: {profile_photo: profile_photo}) }

      context "refreshing profile photo from external network" do
        before do
          profile_photo.expects(:download_from_network!).with(network.to_s)
        end

        it "should return jsend success if save succeeds" do
          user.expects(:save).returns(true)
          submit_photo_form
          response.should be_jsend_success
        end

        it "should return jsend errors if save fails" do
          user.expects(:save).returns(false)
          user.expects(:errors).returns({})
          submit_photo_form
          response.should be_jsend_error
        end
      end
    end

    def submit_photo_form
      xhr :post, :create, {network: network.to_s}.stringify_keys!.merge(format: :json)
    end
  end
end
