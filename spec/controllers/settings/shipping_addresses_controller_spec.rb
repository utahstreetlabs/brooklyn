require 'spec_helper'

describe Settings::ShippingAddressesController do
  let(:user_params) { {'postal_addresses_attributes' => {'foo' => 'bar'}} }

  describe "#index" do
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
    it_behaves_like "secured against anonymous users" do
      before { submit_form }
    end

    context "for a logged-in user" do
      let(:user) { act_as_stub_user }
      let(:postal_address) { stub(:postal_address, id: 1, name: "Sasquatch Jones") }
      let(:postal_addresses) { [postal_address] }

      context "when adding a new address" do
        before do
          user.expects(:postal_addresses_attributes=).with(user_params['postal_addresses_attributes'])
        end
        
        it "updates the shipping address when valid" do
          user.stubs(:postal_addresses).returns([postal_address])
          user.expects(:save).returns(true)
          postal_address.expects(:default!)
          submit_form
          response.should redirect_to(settings_shipping_addresses_path)
          flash[:notice].should be
        end
        
        it "re-renders the page when invalid" do
          user.expects(:postal_addresses).returns([])
          user.expects(:save).returns(false)
          submit_form
          response.should be_success
          response.should render_template(:index)
          flash[:notice].should_not be
        end
      end
    end
  end

  describe "#destroy" do
    it_behaves_like "secured against anonymous users" do
      before { submit_delete }
    end

    context "for a logged-in user" do
      let(:user) { act_as_stub_user }
    
      context "when deleting an existing address" do
        let(:postal_address) { stub(:postal_address, id: 1, name: "Charles Franklin Jebediah McChumchum") }
        let(:postal_addresses) { [postal_address] }
        
        before do
          user.stubs(:postal_addresses).returns(postal_addresses)
        end
        
        it "deletes the shipping address when valid" do
          postal_addresses.expects(:find).returns(postal_address)
          postal_addresses.expects(:destroy).returns
          user.expects(:save).returns(true)
          postal_address.expects(:default!)
          submit_delete
          response.should redirect_to(settings_shipping_addresses_path)
          flash[:notice].should be
        end
      end
    end
  end

  def submit_form
    put :update, user: user_params, id: 1
  end
  
  def submit_delete
    delete :destroy, id: 1
  end
end
