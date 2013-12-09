require 'spec_helper'

describe Orders::Balanced do
  let(:buyer_account) { stub('buyer-account', uri: 'http://balancedpayments.com/accounts/deadbeef') }
  let(:seller_account) { stub('seller-account', uri: 'http://balancedpayments.com/accounts/cafebebe') }
  let(:bank_account) { stub('bank-account', uri: 'http://balancedpayments.com/bank-accounts/abcabc')}
  let(:card) { stub('card', uri: 'http://balancedpayments.com/cards/deadbeef') }
  let(:debit) { stub('debit', uri: 'http://balancedpayments.com/transactions/debit') }
  let(:credit) { stub('credit', uri: 'http://balancedpayments.com/transactions/credit') }
  let(:refund) { stub('credit', uri: 'http://balancedpayments.com/transactions/refund') }
  let(:bank_deposit_account) do
    Factory.create(:bank_account, default: true, user: subject.listing.seller, balanced_url: bank_account.uri)
  end
  let(:paypal_deposit_account) do
    Factory.create(:paypal_account, default: true, user: subject.listing.seller, balanced_url: bank_account.uri)
  end

  before do
    subject.listing.seller.stubs(:balanced_account).returns(seller_account) if subject.listing
  end

  describe '.process_purchase!' do
    context "when the order is purchaseable" do
      subject { FactoryGirl.create(:purchaseable_order) }

      context "when the card is tokenized" do
        before do
          subject.purchase.stubs(:create_card!).returns(card)
          subject.buyer.stubs(:create_buyer!).with(card).returns(buyer_account)
        end

        context "when the payment is accepted" do
          before do
            buyer_account.stubs(:debit).returns(debit)
            subject.process_purchase!
          end
          its(:billing_address) { should be }
          its(:balanced_debit_url) { should == debit.uri }
        end

        context "when the payment is declined" do
          before { buyer_account.stubs(:debit).raises(Balanced::PaymentRequired.new({body: {}})) }
          it 'raises PaymentDeclined' do
            expect { subject.process_purchase! }.to raise_error(Orders::PaymentDeclined)
          end
        end
      end

      context "when the card is rejected" do
        before { subject.purchase.stubs(:create_card!).raises(Purchase::CardRejected.new("Rejected")) }
        it 'raises CardRejected' do
          expect { subject.process_purchase! }.to raise_error(Purchase::CardRejected)
        end
      end

      context "when the card is not validated" do
        before { subject.purchase.stubs(:create_card!).raises(Purchase::CardNotValidated.new("Invalid")) }
        it 'raises CardNotValidated' do
          expect { subject.process_purchase! }.to raise_error(Purchase::CardNotValidated)
        end
      end
    end

    context "when the order has already been debited" do
      subject { FactoryGirl.create(:confirmed_order, balanced_debit_url: debit.uri) }
      it 'raises InvalidPaymentState' do
        expect { subject.process_purchase! }.to raise_error(Orders::InvalidPaymentState)
      end
    end
  end

  describe '.pay_seller!' do
    context "when the order is payable" do
      subject { FactoryGirl.create(:complete_order, balanced_debit_url: debit.uri) }
      before do
        seller_account.stubs(:credit).returns(credit)
        subject.pay_seller!(deposit_account)
      end

      context "and the default deposit account is a bank account" do
        let(:deposit_account) { bank_deposit_account }
        its(:balanced_credit_url) { should == credit.uri }
        its(:paypal_payment) { should be_nil }
      end

      context "and the default deposit account is a paypal account" do
        let(:deposit_account) { paypal_deposit_account }
        its(:balanced_credit_url) { should == credit.uri }
        its(:paypal_payment) { should be }
      end
    end

    context "when the order has not been debited" do
      subject { FactoryGirl.create(:pending_order) }
      it 'raises InvalidPaymentState' do
        expect { subject.pay_seller!(bank_deposit_account) }.to raise_error(Orders::InvalidPaymentState)
      end
    end

    context "when the order has already been credited" do
      # complete_order does not set up a default deposit account because it requires the bank account to be stubbed
      subject { FactoryGirl.create(:complete_order, balanced_debit_url: debit.uri, balanced_credit_url: credit.uri) }
      before do
        bank_deposit_account
        subject.skip_credit = true
        subject.settle!
        subject.skip_credit = false
      end
      it 'raises InvalidPaymentState' do
        expect { subject.pay_seller!(bank_deposit_account) }.to raise_error(Orders::InvalidPaymentState)
      end
    end
  end

  describe '.refund_buyer' do
    context "when the order is refundable" do
      subject { FactoryGirl.create(:confirmed_order, balanced_debit_url: debit.uri) }
      before do
        subject.stubs(:debit).returns(debit)
        debit.stubs(:refund).returns(refund)
        subject.refund_buyer!
      end
      its(:balanced_refund_url) { should == refund.uri }
    end

    context "when the order has not yet been debited" do
      subject { FactoryGirl.create(:pending_order) }
      it 'raises InvalidPaymentState' do
        expect { subject.refund_buyer! }.to raise_error(Orders::InvalidPaymentState)
      end
    end

    context "when the order has already been refunded" do
      subject { FactoryGirl.create(:cancelled_order, balanced_debit_url: debit.uri, balanced_refund_url: refund.uri) }
      it 'raises InvalidPaymentState' do
        expect { subject.refund_buyer! }.to raise_error(Orders::InvalidPaymentState)
      end
    end

    context "when the order has already been refunded out of band" do
      subject { FactoryGirl.create(:confirmed_order, balanced_debit_url: debit.uri) }
      before do
        subject.stubs(:debit).returns(debit)
        debit.stubs(:refund).raises(Balanced::BadRequest.new(body: {category_code: 'invalid-amount'}))
        debit.stubs(:refunds).returns([refund])
      end
      it "updates the order based on the existing refund" do
        expect { subject.refund_buyer! }.to_not raise_error
        subject.balanced_refund_url.should == refund.uri
      end
    end
  end

  describe '.debit' do
    subject { Order.new }
    let(:debit) { mock }
    let(:url) { 'http://balancedpayments.com/debits/deadbeef' }

    it 'preemptively returns nil when there is no debit url' do
      Balanced::Debit.expects(:find).never
      subject.debit.should be_nil
    end

    it 'queries Balanced when there is no memoized debit' do
      subject.balanced_debit_url = url
      Balanced::Debit.expects(:find).with(url).returns(debit)
      subject.debit.should == debit
    end

    it 'returns the memoized debit when there is one' do
      subject.instance_variable_set(:@balanced_debit, debit)
      Balanced::Debit.expects(:find).never
      subject.debit.should == debit
    end
  end

  describe '.credit' do
    subject { Order.new }
    let(:credit) { mock }
    let(:url) { 'http://balancedpayments.com/credits/deadbeef' }

    it 'preemptively returns nil when there is no credit url' do
      Balanced::Credit.expects(:find).never
      subject.credit.should be_nil
    end

    it 'queries Balanced when there is no memoized credit' do
      subject.balanced_credit_url = url
      Balanced::Credit.expects(:find).with(url).returns(credit)
      subject.credit.should == credit
    end

    it 'returns the memoized credit when there is one' do
      subject.instance_variable_set(:@balanced_credit, credit)
      Balanced::Credit.expects(:find).never
      subject.credit.should == credit
    end
  end

  describe '.refund' do
    subject { Order.new }
    let(:refund) { mock }
    let(:url) { 'http://balancedpayments.com/refunds/deadbeef' }

    it 'preemptively returns nil when there is no refund url' do
      Balanced::Refund.expects(:find).never
      subject.refund.should be_nil
    end

    it 'queries Balanced when there is no memoized refund' do
      subject.balanced_refund_url = url
      Balanced::Refund.expects(:find).with(url).returns(refund)
      subject.refund.should == refund
    end

    it 'returns the memoized refund when there is one' do
      subject.instance_variable_set(:@balanced_refund, refund)
      Balanced::Refund.expects(:find).never
      subject.refund.should == refund
    end
  end
end
