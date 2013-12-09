require 'spec_helper'

describe Order do
  it "status is pending by default" do
    Order.new.status.should be === "pending"
  end

  context "when pending" do
    subject { FactoryGirl.create(:pending_order) }

    it "has a reference number" do
      subject.reference_number.should_not be_nil
    end

    it "can be confirmed" do
      subject.can_confirm?.should be_true
    end

    it "is not expired before timeout period" do
      subject.save!
      Order.find_expired(5).should have(0).orders
    end

    it "expires after the provided timeout period" do
      subject.created_at = 20.minutes.ago
      subject.save!
      Order.find_expired(15).should have(1).order
    end

    it "can handle string arguments for expiration time" do
      subject.created_at = 10.minutes.ago
      subject.save!
      Order.find_expired("5").should have(1).order
    end

    it "cannot be confirmed" do
      expect { subject.confirm! }.to raise_error(ArgumentError)
    end
  end

  context "when purchaseable" do
    subject { FactoryGirl.create(:purchaseable_order) }

    context "and transitioning to confirmed" do
      before do
        subject.skip_debit = true
        subject.confirm!
      end

      it { should be_confirmed }
      its(:confirmed_at) { should be }
    end
  end

  context "when confirmed" do
    subject { FactoryGirl.create(:confirmed_order) }

    context "and transitioning to shipped" do
      context "with basic shipping" do
        context "with a shipment" do
          before do
            FactoryGirl.create(:shipment, order: subject)
            subject.ship
          end
          it { should be_shipped }
          its(:shipped_at) { should be }
        end

        context "without a shipment" do
          before { subject.ship }
          it { should_not be_shipped }
        end
      end

      context "with prepaid shipping" do
        context "and an active shipping label" do
          before do
            FactoryGirl.create(:shipping_label, order: subject)
            subject.ship
          end
          it { should be_shipped }
          its(:shipped_at) { should be }
        end

        context "and an expired shipping label" do
          before do
            FactoryGirl.create(:expired_shipping_label, order: subject)
            subject.ship
          end
          it { should_not be_shipped }
        end
      end
    end

    context "and transitioning to cancelled" do
      before do
        subject.skip_refund = true
        subject.cancel!
      end

      its(:canceled?) { should be_true }
      its(:canceled_at) { should be }
    end
  end

  context "when shipped" do
    subject { FactoryGirl.create(:shipped_order) }

    context "and transitioning to delivered" do
      before { subject.deliver! }

      its(:delivered?) { should be_true }
      its(:delivered_at) { should be }
    end

    context 'and transitioning to canceled' do
      before do
        subject.skip_refund = true
        subject.cancel!
      end

      its(:canceled?) { should be_true }
      its(:canceled_at) { should be }
    end
  end

  context "when delivered" do
    subject { FactoryGirl.create(:delivered_order) }

    context "and transitioning to complete" do
      before { subject.complete! }

      its(:complete?) { should be_true }
      its(:completed_at) { should be }
      its(:buyer_rating) { subject.flag.should be_true }
      its(:seller_rating) { subject.flag.should be_true }
    end

    context 'and transitioning to canceled' do
      before do
        subject.skip_refund = true
        subject.cancel!
      end

      its(:canceled?) { should be_true }
      its(:canceled_at) { should be }
    end
  end

  context "when complete" do
    subject { FactoryGirl.create(:complete_order) }

    context 'and transitioning to settled' do
      before do
        subject.expects(:pay_seller!)
        subject.settle!
      end

      its(:settled?) { should be_true }
      its(:settled_at) { should be_true }
    end
  end

  describe 'after create' do
    subject { FactoryGirl.build(:pending_order) }

    it 'enqueues Orders::AfterCreationJob' do
      Orders::AfterCreationJob.expects(:enqueue).with(is_a(Integer))
      subject.save!
    end
  end

  describe 'after cancel' do
    subject do
      order = FactoryGirl.create(:confirmed_order)
      FactoryGirl.create(:shipping_label, order: order)
      order
    end

    before do
      subject.skip_refund = true
      subject.cancel!
    end

    it "creates a cancelled order" do
      cancelled = CancelledOrder.find(subject.id)
      cancelled.should be
      cancelled.shipping_address.should be
      cancelled.billing_address.should be
      cancelled.shipping_label.should be
    end

    it "is destroyed" do
      expect { subject.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#destroy" do
    it "relists a sold listing" do
      order = FactoryGirl.create(:confirmed_order)
      order.listing.should be_sold
      order.destroy
      order.listing.should be_active
    end
  end

  describe '#finalized?' do
    #XXX: add , :return_completed when we support returns
    [:settled].each do |state|
      it "returns true when state is #{state}" do
        FactoryGirl.create("#{state}_order").finalized?.should be_true
      end
    end

    #XXX: add , :return_pending, :return_shipped, :return_delivered when we support returns
    [:pending, :confirmed, :shipped, :delivered, :complete].each do |state|
      it "returns false when state is #{state}" do
        FactoryGirl.create("#{state}_order").finalized?.should be_false
      end
    end
  end

  describe '#find_for_user' do
    it 'should return orders associated with a user' do
      order = FactoryGirl.create('confirmed_order')
      order.listing.seller.orders.should == [order]
    end
  end

  describe "#total_price" do
    it "matches the listing's total price if there is no credit applied" do
      order = FactoryGirl.create(:pending_order)
      order.total_price.should == order.listing.total_price
    end

    it "equals the listing's total price minus the credit amount" do
      order = FactoryGirl.create(:pending_order)
      debit = FactoryGirl.create(:debit, credit: FactoryGirl.create(:credit), order: order, amount: 10)
      order.total_price.should == (order.listing.total_price - debit.amount)
    end
  end

  describe "add credit amount" do
    let(:credit_balance) { 100 }
    let(:listing_price) { 150 }
    let(:listing) { FactoryGirl.create(:active_listing, price: listing_price, shipping: 0) }
    subject { FactoryGirl.create(:pending_order, listing: listing) }
    before do
      FactoryGirl.create(:credit, amount: credit_balance, user: subject.buyer)
      subject.buyer.save!
      subject.listing.price = listing_price
      subject.listing.save!
    end

    it "should apply credit amount if credit amount is less than buyer credit" do
      credit_amount = credit_balance - 10
      expect { subject.apply_credit_amount!(credit_amount) }.to_not raise_exception
      subject.reload.credit_amount.should == credit_amount
      subject.buyer.reload.credit_balance.should == (credit_balance - credit_amount)
    end

    context "in the face of floating point insanity" do
      let(:listing_price) { 10 }
      it "should apply credit amount correctly" do
        # 10.60 - 9.59 == 1.0099999999999998 so make sure this
        # doesn't explode
        credit_amount = 10.60 - Credit.minimum_real_charge - 0.01
        expect { subject.apply_credit_amount!(credit_amount) }.to_not raise_exception
        subject.reload.credit_amount.should == credit_amount
        subject.buyer.reload.credit_balance.should == (credit_balance - credit_amount.to_d)
      end
    end

    context "in the face of more floating point insanity" do
      let(:listing_price) { 5.65 }
      it "should apply credit amount correctly" do
        # total_price ends up being 5.989, so 5.98 credit fails
        credit_amount = 5.99 - Credit.minimum_real_charge
        expect { subject.apply_credit_amount!(credit_amount) }.to_not raise_exception
        subject.reload.credit_amount.should == credit_amount
        subject.buyer.reload.credit_balance.should == (credit_balance - credit_amount.to_d)
      end
    end

    it "should fail to apply credit if credit amount is greater than buyer credit" do
      credit_amount = credit_balance + 10
      expect { subject.apply_credit_amount!(credit_amount) }.to raise_exception(Credit::NotEnoughCreditAvailable)
      subject.reload.credit_amount.should == 0
      subject.buyer.reload.credit_balance.should == credit_balance
    end

    context "when credit_balance is greater than listing price" do
      let(:credit_balance) { listing_price + 50 }
      it "should fail to save if credit amount is greater than listing price" do
        credit_amount = listing_price + 10
        expect { subject.apply_credit_amount!(credit_amount) }.to raise_exception(Credit::MinimumRealChargeRequired)
        subject.reload.credit_amount.should == 0
        subject.buyer.reload.credit_balance.should == credit_balance
      end

      it "should fail to apply credit if credit amount is exactly the total price of the listing" do
        credit_amount = listing.total_price
        expect { subject.apply_credit_amount!(credit_amount) }.to raise_exception(Credit::MinimumRealChargeRequired)
        subject.credit_amount.should == 0
      end
    end

    it "should be refunded upon destruction" do
      credit_amount = credit_balance - 10
      buyer = subject.buyer
      expect { subject.apply_credit_amount!(credit_amount) }.to_not raise_exception
      buyer.reload.credit_balance.should == (credit_balance - credit_amount)
      subject.reload.destroy.should be_true
      buyer.reload.credit_balance.should == credit_balance
    end

    it "should not double debit if credit_amount is set twice" do
      credit_amount = 10
      expect { subject.apply_credit_amount!(credit_amount) }.to_not raise_exception
      subject.buyer.reload.credit_balance.should == (credit_balance - credit_amount)
      credit_amount_two = 15
      expect { subject.apply_credit_amount!(credit_amount_two) }.to_not raise_exception
      subject.reload.credit_amount.should == credit_amount_two
      subject.buyer.reload.credit_balance.should == (credit_balance - credit_amount_two)
    end

    it "should not count old credit amount when validating that new credit amount is less than credit balance" do
      credit_amount = 60
      subject.apply_credit_amount!(credit_amount)
      subject.save.should be_true
      subject.buyer.reload.credit_balance.should == (credit_balance - credit_amount)
      credit_amount_two = 70
      expect { subject.apply_credit_amount!(credit_amount) }.to_not raise_exception
    end
  end

  describe '#applicable_credit' do
    let(:listing) { FactoryGirl.create(:active_listing, price: 25, shipping: 0) }
    subject { FactoryGirl.create(:pending_order, listing: listing) }

    context 'when balance is less than listing total price' do
      let(:balance) { listing.total_price - 5}

      it 'should return the entire balance' do
        subject.applicable_credit(balance).should == balance
      end
    end

    context 'when balance is greater than listing total price' do
      let(:balance) { listing.total_price + 5 }

      it 'should return the listing total price less the minimum charge' do
        subject.applicable_credit(balance).should == listing.total_price - Credit.minimum_real_charge
      end
    end
  end

  describe "#buyer_fee" do
    it "should equal the listing buyer fee if the order has no credit applied" do
      order = FactoryGirl.create('pending_order')
      order.buyer_fee.should == order.buyer_fee
    end

    it "should equal the listing buyer fee minus credit_amount" do
      type = :invitee
      order = FactoryGirl.create('pending_order')
      Lagunitas::CreditTrigger.expects(:create).with(type.to_s.classify, order.buyer_id, is_a(Integer),
        is_a(Hash))
      Credit.grant!(order.buyer, type)
      credit_amount = order.buyer.credit_balance
      order.apply_credit_amount!(credit_amount)
      order.buyer_fee.should == (order.listing.buyer_fee - credit_amount)
    end
  end

  describe "#api_hash" do
    subject { order.api_hash }

    context "pending" do
      let(:order) { FactoryGirl.create(:pending_order) }

      its([:reference]) { should == order.reference_number }
      its([:status]) { should == order.status }
      it "only has buyer name" do
        subject[:buyer].should have(3).items
        subject[:buyer][:name].should == order.buyer.name
      end
      its([:listing]) { should == order.listing.api_hash }
    end

    context "confirmed" do
      let(:order) { FactoryGirl.create(:confirmed_order) }

      it "provides buyer shipping info" do
        buyer = subject[:buyer]
        [:line1, :line2, :city, :state, :zip, :phone].each do |key|
          buyer[key].should == order.shipping_address.send(key)
        end
      end
    end
  end

  describe "#find_confirmed_unshipped_to_be_cancelled" do
    it "finds orders more than 48 hours past their handling time" do
      # set start time to 2012/1/1 to avoid hitting daylight savings time in this test
      # it's fine that this is off by an hour during daylight savings - just means
      # users will have one hour of additional cancellation buffer
      Timecop.travel(Date.new(2012, 1, 1)) do
        order1 = order_with_handling_time(4.days)
        order2 = order_with_handling_time(4.days + 20.minutes)
        Timecop.travel(4.days + Order.confirmed_unshipped_cancellation_buffer + 10.minutes) do
          Order.find_confirmed_unshipped_to_be_cancelled.should == [order1]
          Timecop.travel(15.minutes) do
            Order.find_confirmed_unshipped_to_be_cancelled.should == [order1, order2]
          end
        end
      end
    end
  end

  describe '#find_to_request_delivery_confirmation' do
    let!(:order) { FactoryGirl.create(:shipped_order) }

    it 'does not find the order before the delivery confirmation period has expired' do
      Order.find_to_request_delivery_confirmation.should be_empty
    end

    it 'does not find the order when confirmation has already been requested' do
      order.update_column(:delivery_confirmation_requested_at, Time.zone.now)
      Timecop.travel(order.shipped_at + Order.delivery_confirmation_period_duration + 1.day) do
        Order.find_to_request_delivery_confirmation.should be_empty
      end
    end

    it 'finds the order after the delivery confirmation period has expired' do
      Timecop.travel(order.shipped_at + Order.delivery_confirmation_period_duration + 1.day) do
        Order.find_to_request_delivery_confirmation.should == [order]
      end
    end
  end

  describe '#find_to_follow_up_on_delivery_non_confirmation' do
    let!(:order) { FactoryGirl.create(:shipped_order) }

    it 'does not find the order before the grace period has expired' do
      Order.find_to_follow_up_on_delivery_non_confirmation.should be_empty
    end

    it 'does not find the order when already followed up on' do
      order.update_column(:delivery_confirmation_followed_up_at, Time.zone.now)
      Order.find_to_follow_up_on_delivery_non_confirmation.should be_empty
    end

    it 'finds the order after the grace period has expired' do
      requested_at = requested_at =  Time.zone.now - Order.delivery_non_confirmation_followup_period_duration - 1.day
      order.update_column(:delivery_confirmation_requested_at, requested_at)
      Order.find_to_follow_up_on_delivery_non_confirmation.should == [order]
    end
  end

  describe "#confirm" do
    it "should mark a listing sold if it is not already" do
      order = FactoryGirl.create(:purchaseable_order, listing: FactoryGirl.create(:active_listing))
      order.listing.sold?.should be_false # just make sure the test data is correct
      order.skip_debit = true
      order.confirm!
      order.listing.sold?.should be_true
    end
  end

  describe '#delivery_confirmation_elapsed' do
    context 'when the order has not been shipped' do
      subject { FactoryGirl.create(:pending_order) }
      its(:delivery_confirmation_elapsed?) { should be_false }
    end

    context "when the order has been shipped" do
      subject { FactoryGirl.create(:shipped_order) }

      context "but its delivery confirmation period has not elapsed" do
        its(:delivery_confirmation_elapsed?) { should be_false }
      end

      context "and its delivery confirmation period has elapsed" do
        it 'returns true' do
          Timecop.travel(subject.shipped_at + Order.delivery_confirmation_period_duration + 1.day) do
            subject.delivery_confirmation_elapsed?.should be_true
          end
        end
      end
    end

    context "when the order has been delivered" do
      subject { FactoryGirl.create(:delivered_order) }

      context "but its delivery confirmation period has not elapsed" do
        its(:delivery_confirmation_elapsed?) { should be_false }
      end

      context "and its delivery confirmation period has elapsed" do
        it 'returns true' do
          Timecop.travel(subject.shipped_at + Order.delivery_confirmation_period_duration + 1.day) do
            subject.delivery_confirmation_elapsed?.should be_true
          end
        end
      end
    end
  end

  describe '#handling_reminder_after' do
    let(:order) { FactoryGirl.create(:pending_order) }
    let(:listing) { order.listing }
    subject { order }

    context "when the handling period is full length" do
      before { listing.handling_duration = Order.handling_period_reminder_abbrev_threshold + 1.day }
      its(:handling_reminder_after) { should == order.handling_duration - Order.handling_period_full_reminder_window }
    end

    context "when the handling period is abbreviated" do
      before { listing.handling_duration = Order.handling_period_reminder_none_threshold + 1.day }
      its(:handling_reminder_after) { should == order.handling_duration - Order.handling_period_abbrev_reminder_window }
    end

    context "when there is effectively no handling period" do
      before { listing.handling_duration = Order.handling_period_reminder_none_threshold - 1.hour }
      its(:handling_reminder_after) { should be_nil }
    end
  end
end
