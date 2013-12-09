require 'spec_helper'

describe OffersController do
  let(:offer_uuid) { 'abcdef' }
  let(:destination_url) { '' }
  let(:present) { false }
  let(:offer) do
    stub_everything('offer', id: 1, uuid: offer_uuid, destination_url: destination_url,
      destination_url_present?: present)
  end
  before { Offer.expects(:find_by_uuid).with(offer_uuid).returns(offer) }

  describe "#show" do
    context "for a logged in user" do
      let!(:user) { act_as_stub_user }

      context "when in preview mode" do
        it "shows the offer page" do
          get :show, id: offer_uuid, preview: '1'
          response.should render_template(:show)
        end
      end

      context "when not in preview mode" do
        before { offer.expects(:earn).with(user) }

        it "should redirect to logged in home" do
          get :show, id: offer_uuid
          response.should redirect_to(root_path)
        end

        context "when the offer has a destination_url" do
          let(:destination_url) { 'http://example.com/listings/some-listing' }
          let(:present) { true }

          it "should redirect to the destination url" do
            get :show, id: offer_uuid
            response.should redirect_to(destination_url)
          end
        end
      end
    end

    context "for a guest user" do
      let!(:user) { act_as_guest_user }
      before { get :show, id: offer_uuid }

      it "should assign the correct offer" do
        assigns(:offer).should == offer
      end

      it "should store the offer id in the session" do
        session[:offer_id].should == offer_uuid
      end

      it "should store login and register redirects" do
        controller.stored_register_redirect.should == root_path
        controller.stored_login_redirect.should == root_path
      end

      context "when the offer has a destination_url" do
        let(:destination_url) { 'http://example.com/listings/some-listing' }
        let(:present) { true }

        it "should redirect to the destination url" do
          controller.stored_register_redirect.should == destination_url
          controller.stored_login_redirect.should == destination_url
        end
      end
    end
  end

  describe "#accept" do
    context "with a 'd' parameter" do
      let!(:user) { act_as_guest_user }
      let(:destination) { '/profiles/carrie-fisher' }
      let(:network) { :facebook }
      before { get :accept, offer_id: offer_uuid, d: destination, n: network}

      it "should redirect to auth" do
        response.should redirect_to(subject.send(:auth_path, network, d: destination))
      end
    end
  end
end
