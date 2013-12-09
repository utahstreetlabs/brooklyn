require 'spec_helper'

describe Listings::PurchaseController do
  let(:buyer) { FactoryGirl.create(:registered_user) }
  let(:listing) { FactoryGirl.create(:active_listing) }
  let(:order) { stub_order listing, persisted?: true }

  before do
    act_as(buyer)
    InternalListing.any_instance.stubs(:initiate_order).with(buyer).returns(order)
    Order.any_instance.stubs(:skip_debit).returns(true)
  end

  context "#show" do
    before do
      listing.save!
    end

    it "sets the listing" do
      submit_buy_now_form
      assigns(:listing).should eq(listing)
    end

    context "for an inactive listing" do
      before { listing.suspend! }

      it "redirects to the dashboard" do
        submit_buy_now_form
        response.should be_redirected_to_home_page
      end
    end

    context "by an anonymous user" do
      before { act_as(nil) }

      it "redirects to the listing page" do
        submit_buy_now_form
        response.should be_redirected_to_auth_page
      end
    end

    context "by the seller" do
      before { act_as(listing.seller) }

      it "redirects to the listing page" do
        submit_buy_now_form
        response.should be_redirected_to_listing_page
      end
    end

    context "for a listing with an order" do
      before { order.stubs(:persisted?).returns(false) }

      it "redirects to the listing page" do
        submit_buy_now_form
        flash[:notice].should have_flash_message('purchase.create_failed')
        response.should be_redirected_to_listing_page
      end
    end

    it "initiates an order" do
      listing.order.should be_nil
      submit_buy_now_form
      assigns(:order).should == order
    end

    it "redirects to the shipping page" do
      submit_buy_now_form
      response.should redirect_to(shipping_listing_purchase_path(listing))
    end

    it "tracks usage" do
      subject.expects(:track_usage).with(:initiate_order)
      submit_buy_now_form
    end
  end

  context "#shipping" do
    before { listing.order = FactoryGirl.create(:pending_order, listing: listing, buyer: buyer) }

    it "sets the listing" do
      visit_shipping_page
      assigns(:listing).should eq(listing)
    end

    context "for an inactive listing" do
      before { listing.suspend! }

      it "redirects to the dashboard" do
        visit_shipping_page
        response.should be_redirected_to_home_page
      end
    end

    context "by an anonymous user" do
      before { act_as(nil) }

      it "redirects to the listing page" do
        visit_shipping_page
        response.should be_redirected_to_auth_page
      end
    end

    context "by the seller" do
      before { act_as(listing.seller) }

      it "redirects to the listing page" do
        visit_shipping_page
        response.should be_redirected_to_listing_page
      end
    end

    context "by an arbitrary user" do
      before { act_as(Factory.create(:registered_user)) }

      it "redirects to the listing page" do
        visit_shipping_page
        response.should be_redirected_to_listing_page
      end
    end

    context "for a listing without an order" do
      before { listing.order = nil }

      it "redirects to the listing page" do
        visit_shipping_page
        response.should be_redirected_to_listing_page
      end
    end

    context "when buyer has shipping addresses" do
      let!(:shipping_address) { buyer.postal_addresses.create(FactoryGirl.attributes_for(:shipping_address)) }

      before { visit_shipping_page }

      it 'assigns ship_to with selected address' do
        assigns(:ship_to).master_addresses.should == [shipping_address]
        assigns(:ship_to).address_id.should == shipping_address.id
        assigns(:ship_to).bill_to_shipping.should be_true
      end

      it 'assigns address' do
        assigns(:address).should be_a(PostalAddress)
        assigns(:address).should_not be_persisted
      end
    end

    context "when buyer has no shipping addresses" do
      before { visit_shipping_page }

      it 'assigns ship_to without selected address' do
        assigns(:ship_to).master_addresses.should be_empty
        assigns(:ship_to).address_id.should be_nil
        assigns(:ship_to).bill_to_shipping.should be_true
      end

      it 'assigns address' do
        assigns(:address).should be_a(PostalAddress)
        assigns(:address).should_not be_persisted
      end
    end
  end

  context "#create_shipping_address" do
    before { listing.order = FactoryGirl.create(:pending_order, listing: listing, buyer: buyer) }

    let(:name) { 'Home'}
    let(:line1) { '157 Bedford Ave' }
    let(:line2) { 'Apt 4' }
    let(:city) { 'Brooklyn' }
    let(:state) { 'NY' }
    let(:zip) { '11215' }
    let(:phone) { '(718) 555-1212' }

    it "sets the listing" do
      visit_shipping_page
      assigns(:listing).should eq(listing)
    end

    context "for an inactive listing" do
      before { listing.suspend! }

      it "redirects to the dashboard" do
        visit_shipping_page
        response.should be_redirected_to_home_page
      end
    end

    context "by an anonymous user" do
      before { act_as(nil) }

      it "redirects to the listing page" do
        visit_shipping_page
        response.should be_redirected_to_auth_page
      end
    end

    context "by the seller" do
      before { act_as(listing.seller) }

      it "redirects to the listing page" do
        visit_shipping_page
        response.should be_redirected_to_listing_page
      end
    end

    context "by an arbitrary user" do
      before { act_as(Factory.create(:registered_user)) }

      it "redirects to the listing page" do
        visit_shipping_page
        response.should be_redirected_to_listing_page
      end
    end

    context "for a listing without an order" do
      before { listing.order = nil }

      it "redirects to the listing page" do
        visit_shipping_page
        response.should be_redirected_to_listing_page
      end
    end

    it "redirects to the payment page" do
      submit_new_address_form
      response.status.should be_redirected_to_payment_page
    end

    it "assigns and saves the address" do
      submit_new_address_form
      assigns(:address).persisted?.should be_true
    end

    [:name, :line1, :city, :state, :zip, :phone].each do |field|
      it "fails when #{field} is blank" do
        submit_new_address_form field => nil
        response.should_not be_redirected_to_listing_page
        assigns(:address).persisted?.should_not be_true
        assigns(:address).errors[field].should have(1).error
      end
    end

    it "fails when state is not a known US state code" do
      submit_new_address_form :state => 'VIC'
      response.should_not be_redirected_to_listing_page
      assigns(:address).persisted?.should_not be_true
      assigns(:address).errors[:state].should have(1).error
    end

    it "fails when zip is invalid" do
      submit_new_address_form :zip => '1234'
      response.should_not be_redirected_to_listing_page
      assigns(:address).persisted?.should_not be_true
      assigns(:address).errors[:zip].should have(1).error
    end

    it "fails when phone is invalid" do
      submit_new_address_form :phone => '1234'
      response.should_not be_redirected_to_listing_page
      assigns(:address).persisted?.should_not be_true
      assigns(:address).errors[:phone].should have(1).error
    end

    it "fails when name and address is taken" do
      FactoryGirl.create(:shipping_address, :name => 'Taken', :line1 => '11 Foo St.', :user => buyer)
      submit_new_address_form :name => 'Taken', :line1 => '11 Foo St.'
      response.should_not be_redirected_to_listing_page
      assigns(:address).persisted?.should_not be_true
      assigns(:address).errors[:name].should have(1).error
    end

    def submit_new_address_form(params = {})
      pa_params = {:name => name, :line1 => line1, :line2 => line2, :city => city, :state => state, :zip => zip,
        :phone => phone}.merge(params)
      post :create_shipping_address, :listing_id => listing.to_param, :postal_address => pa_params
    end
  end

  context "#ship_to" do
    let!(:order) { listing.create_order(FactoryGirl.attributes_for(:pending_order, buyer: buyer)) }
    let!(:shipping_address) { buyer.postal_addresses.create(FactoryGirl.attributes_for(:shipping_address)) }

    before do
      listing.stubs(:order).returns(order)
    end

    context "for an inactive listing" do
      before { listing.suspend! }

      it "redirects to the dashboard" do
        submit_ship_to_form
        response.should be_redirected_to_home_page
      end
    end

    context "by an anonymous user" do
      before { act_as(nil) }

      it "redirects to the listing page" do
        submit_ship_to_form
        response.should be_redirected_to_auth_page
      end
    end

    context "by the seller" do
      before { act_as(listing.seller) }

      it "redirects to the listing page" do
        submit_ship_to_form
        response.should be_redirected_to_listing_page
      end
    end

    context "by an arbitrary user" do
      before { act_as(Factory.create(:registered_user)) }

      it "redirects to the listing page" do
        submit_ship_to_form
        response.should be_redirected_to_listing_page
      end
    end

    context "for a listing without an order" do
      before { listing.order = nil }

      it "redirects to the listing page" do
        submit_ship_to_form
        response.should be_redirected_to_listing_page
      end
    end

    it "should redisplay the shipping page if the ship_to form is invalid" do
      submit_ship_to_form(ship_to: {})
      response.should render_template(:shipping)
      flash[:alert].should_not be_nil
    end

    context "successfully" do
      before do
        subject.class.expects(:listing_scope).returns(stub(:find_by_slug! => listing))
      end

      it "updates the order" do
        order.expects(:save!)
        submit_ship_to_form
        order.shipping_address.equivalent?(shipping_address).should be_true
        order.bill_to_shipping.should be_true
      end
    end

    def submit_ship_to_form(params = {})
      params.reverse_merge!(listing_id: listing.to_param,
        ship_to: {address_id: shipping_address.id, bill_to_shipping: '1'})
      post :ship_to, params
    end
  end

  context "#payment" do
    context "for a listing with a purchaseable order" do
      before do
        listing.order = FactoryGirl.create(:purchaseable_order, :listing => listing, buyer: buyer)
      end

      context "that is inactive" do
        before { listing.suspend! }

        it "redirects to the dashboard" do
          visit_payment_page
          response.should be_redirected_to_home_page
        end
      end

      context "by an anonymous user" do
        before { act_as(nil) }

        it "redirects to the listing page" do
          visit_payment_page
          response.should be_redirected_to_auth_page
        end
      end

      context "by the seller" do
        before { act_as(listing.seller) }

        it "redirects to the listing page" do
          visit_payment_page
          response.should be_redirected_to_listing_page
        end
      end

      context "by an arbitrary user" do
        before { act_as(Factory.create(:registered_user)) }

        it "redirects to the listing page" do
          visit_payment_page
          response.should be_redirected_to_listing_page
        end
      end

      context "by the buyer" do
        before { act_as(listing.buyer) }

        it "sets the listing" do
          visit_payment_page
          assigns(:listing).should eq(listing)
        end
      end
    end

    context "for a listing without an order" do
      it "redirects to the listing page with a flash" do
        visit_payment_page
        response.should be_redirected_to_listing_page
        flash[:alert].should have_flash_message('purchase.order.nil.payment')
      end
    end

    context "for a listing with a pending but not purchaseable order" do
      before do
        listing.create_order(FactoryGirl.attributes_for(:pending_order, buyer: FactoryGirl.create(:registered_user)))
        act_as listing.buyer
      end

      it "redirects to the payment page" do
        visit_payment_page
        response.should redirect_to(shipping_listing_purchase_path(listing))
      end
    end

    def visit_payment_page
      get :payment, :listing_id => listing.to_param
    end
  end

  describe "#sell" do
    context "for a listing with a pending order with a shipping address" do
      before do
        listing.order = FactoryGirl.create(:pending_order, listing: listing, buyer: buyer)
        listing.order.shipping_address = FactoryGirl.create(:shipping_address, order: listing.order, user: buyer)
      end

      it "sells the listing" do
        submit_sell_form
        response.should be_redirected_to_listing_page
        assigns(:listing).reload
        assigns(:listing).should be_sold
        assigns(:listing).order.should be_confirmed
        flash[:notice].should have_flash_message('purchase.created')
      end

      it "rejects invalid parameters" do
        submit_sell_form cardholder_name: ''
        assigns(:listing).should_not be_sold
        assigns(:listing).order.should_not be_confirmed
        response.should render_template(:payment)
      end

      it 'handles invalid card info' do
        Order.any_instance.stubs(:confirm!).raises(Purchase::CardNotValidated.new("Invalid"))
        submit_sell_form
        assigns(:listing).should_not be_sold
        assigns(:listing).order.should_not be_confirmed
        response.should render_template(:payment)
      end

      it 'handles rejected card' do
        Order.any_instance.stubs(:confirm!).raises(Purchase::CardRejected.new("Bogus"))
        submit_sell_form
        assigns(:listing).should_not be_sold
        assigns(:listing).order.should_not be_confirmed
        response.should render_template(:payment)
      end

      it 'handles declined payment' do
        Order.any_instance.stubs(:confirm!).raises(Orders::PaymentDeclined.new("Declined"))
        submit_sell_form
        assigns(:listing).should_not be_sold
        assigns(:listing).order.should_not be_confirmed
        response.should render_template(:payment)
      end

      context "that is inactive" do
        before { listing.suspend! }

        it "redirects to the dashboard" do
          submit_sell_form
          response.should be_redirected_to_home_page
        end
      end

      context "by an anonymous user" do
        before { act_as(nil) }

        it "redirects to the home page" do
          submit_sell_form
          response.should be_redirected_to_auth_page
        end
      end

      context "by the seller" do
        before { act_as(listing.seller) }

        it "redirects to the listing page" do
          submit_sell_form
          response.should be_redirected_to_listing_page
        end
      end

      context "by an arbitrary user" do
        before { act_as(Factory.create(:registered_user)) }

        it "redirects to the listing page" do
          submit_sell_form
          response.should be_redirected_to_listing_page
        end
      end
    end

    context "for a listing with a confirmed order" do
      before do
        listing.order = FactoryGirl.create(:confirmed_order, listing: listing, buyer: buyer)
      end

      context "by an anonymous user" do
        before { act_as(nil) }

        it "redirects to the home page" do
          submit_sell_form
          response.should be_redirected_to_auth_page
        end
      end

      context "by the seller" do
        before { act_as(listing.seller) }

        it "redirects to the listing page" do
          submit_sell_form
          response.should be_redirected_to_listing_page
        end
      end

      context "by an arbitrary user" do
        before { act_as(Factory.create(:registered_user)) }

        it "redirects to the listing page" do
          submit_sell_form
          response.should be_redirected_to_listing_page
        end
      end

      it "redirects to the listing page" do
        submit_sell_form
        response.should be_redirected_to_listing_page
      end
    end

    context "for a listing without an order" do
      it "does not sell the listing" do
        submit_sell_form
        assigns(:listing).should_not be_sold
      end

      it "redirects to the listing page with a flash message" do
        submit_sell_form
        response.should be_redirected_to_listing_page
        flash[:alert].should have_flash_message('purchase.order.nil.sell')
      end
    end

    def submit_sell_form(attrs = {})
      purchase_attrs = attrs.reverse_merge(
        cardholder_name: 'Ix Jonez',
        card_number: '4111111111111111',
        :'expires_on(1i)' => '2015',
        :'expires_on(2i)' => '12',
        :'expires_on(3i)' => '01',
        security_code: '123',
        line1: '57 Carmelita St',
        line2: '',
        city: 'San Francisco',
        state: 'CA',
        zip: '94117',
        phone: '(415) 123-4567',
        bill_to_shipping: '1'
      )
      post :sell, :listing_id => listing.to_param, purchase: purchase_attrs
    end
  end

  describe "#destroy" do
    context "for a listing with a pending order" do
      before do
        subject.class.stubs(:listing_scope).returns(stub(:find_by_slug! => listing))
        listing.order = FactoryGirl.create(:pending_order, listing: listing, buyer: buyer)
      end

      context "that is inactive" do
        before { listing.suspend! }

        it "redirects to the home page" do
          click_cancel_link
          response.should be_redirected_to_home_page
        end
      end

      context "by an anonymous user" do
        before { act_as(nil) }

        it "redirects to the signup page" do
          click_cancel_link
          response.should be_redirected_to_auth_page
        end
      end

      context "by the seller" do
        before { act_as(listing.seller) }

        it "redirects to the listing page" do
          click_cancel_link
          response.should be_redirected_to_listing_page
        end
      end

      context "by an arbitrary user" do
        before { act_as(Factory.create(:registered_user)) }

        it "redirects to the listing page" do
          click_cancel_link
          response.should be_redirected_to_listing_page
        end
      end

      context 'and canceling the order succeeds' do
        before { listing.order.expects(:cancel!) }

        context 'when cancel is the result of timer expiration' do
          it "should redirect to the home page with a notice" do
            click_cancel_link(reserved_time_expired: true)
            flash[:notice].should have_flash_message('purchase.reserved_time_expired')
            response.should be_redirected_to_listing_page
          end
        end

        context 'when cancel was triggered by a user' do
          it "should redirect to the home page with a notice" do
            click_cancel_link
            flash[:notice].should have_flash_message('purchase.canceled')
            response.should be_redirected_to_listing_page
          end
        end
      end

      context 'and canceling the order fails' do
        before { listing.order.expects(:cancel!).raises('Oh no!') }

        it "should redirect to the home page with an error" do
          click_cancel_link
          flash[:error].should be
          response.should be_redirected_to_listing_page
        end
      end
    end

    context "for a listing without an order" do
      it "redirects to the listing page" do
        click_cancel_link
        response.should be_redirected_to_listing_page
      end
    end

    def click_cancel_link(options = {})
      delete :destroy, {:listing_id => listing.to_param}.merge(options)
    end
  end

  describe "#credit" do
    let(:credit_balance) { 100 }
    let(:listing_price) { 150 }
    let(:total_price) { listing_price - credit_amount }
    let(:order) { stub_order listing, status: 'pending', buyer: buyer, total_price: total_price }

    before do
      subject.class.expects(:listing_scope).returns(stub(:find_by_slug! => listing))
      listing.stubs(order: order)
    end

    context 'when credit amount is less than credit balance' do
      let(:credit_amount) { credit_balance - 10 }

      it 'should succeed' do
        order.expects(:apply_credit_amount!).with(credit_amount)
        order.expects(:credit_amount).returns(credit_amount)
        buyer.expects(:credit_balance).with(listing: listing).returns(credit_balance)
        order.expects(:applicable_credit).with(credit_balance).returns(credit_balance)
        click_apply_credit
        response.should be_jsend_success
        response.jsend_data['message'].should be
        response.jsend_data['applied'].to_f.should == credit_amount
        response.jsend_data['balance'].to_f.should == credit_balance
        response.jsend_data['applicable'].to_f.should == credit_balance
        response.jsend_data['total'].to_f.should == total_price
      end
    end

    context 'when credit amount is more than credit balance' do
      let(:credit_amount) { credit_balance + 10 }

      it 'should fail' do
        order.expects(:apply_credit_amount!).with(credit_amount).raises(Credit::NotEnoughCreditAvailable)
        click_apply_credit
        response.should be_jsend_failure
        response.jsend_data['message'].should be
      end
    end

    context 'when credit amount is more than listing price' do
      let(:credit_amount) { listing.total_price + 10 }

      it 'should fail' do
        order.expects(:apply_credit_amount!).with(credit_amount).raises(Credit::MinimumRealChargeRequired)
        click_apply_credit
        response.should be_jsend_failure
        response.jsend_data['message'].should be
      end
    end

    def click_apply_credit
      xhr :put, :credit, listing_id: listing.to_param, credit_amount: credit_amount, format: :json
    end
  end

  def visit_shipping_page
    get :shipping, listing_id: listing.to_param
  end

  def be_redirected_to_listing_page
    redirect_to(listing_path(listing))
  end

  def be_redirected_to_payment_page
    redirect_to(payment_listing_purchase_path(listing))
  end

  def submit_buy_now_form(params = {})
    get :show, {:listing_id => listing.to_param}.merge(params)
  end
end
