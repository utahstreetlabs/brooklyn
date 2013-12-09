require 'spec_helper'

describe Settings::ShippingAddresses::DefaultController do

  describe "#update" do
    it_behaves_like "secured against anonymous users" do
      before { submit_update }
    end
    
    context "for a logged-in user" do
      let(:user) { act_as_stub_user }
      
      context "when updating an existing address" do
        let(:postal_address) { stub(:postal_address, id: 1, name: "Rusty Jones") }
        let(:postal_addresses) { [postal_address] }
        
        before do
          user.stubs(:postal_addresses).returns(postal_addresses)
        end
        
        it "sets the address to the default" do
          postal_addresses.expects(:find).returns(postal_address)
          postal_address.expects(:default!)
          submit_update
          response.should redirect_to(settings_shipping_addresses_path)
          flash[:notice].should be
        end
      end
    end
  end

  def submit_update
    put :update, shipping_address_id: 1
  end
end
