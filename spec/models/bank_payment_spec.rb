require 'spec_helper'

describe BankPayment do
  describe '.sync_state!' do
    subject { FactoryGirl.create(:bank_payment) }

    context "when the order has a credit" do
      let(:credit) { stub('credit') }
      before { subject.order.stubs(:credit).returns(credit) }

      context "with pending state" do
        before { credit.stubs(:state).returns('pending') }

        it "does nothing" do
          subject.sync_state!
          subject.should be_pending
        end
      end

      context "with cleared state" do
        before { credit.stubs(:state).returns('cleared') }

        it "changes the payment's state to paid" do
          subject.sync_state!
          subject.should be_paid
        end
      end

      context "with rejected state" do
        before { credit.stubs(:state).returns('rejected') }

        it "changes the payment's state to rejected" do
          subject.sync_state!
          subject.should be_rejected
        end
      end

      context "with canceled state" do
        before { credit.stubs(:state).returns('canceled') }

        it "changes the payment's state to canceled" do
          subject.sync_state!
          subject.should be_canceled
        end
      end

      context "with bogus state" do
        before { credit.stubs(:state).returns('bogus') }

        it "raises an error" do
          expect { subject.sync_state! }.to raise_error(BankPayment::SyncStateError)
        end
      end

      context "with blank state" do
        before { credit.stubs(:state).returns('') }

        it "raises an error" do
          expect { subject.sync_state! }.to raise_error(BankPayment::SyncStateError)
        end
      end
    end

    context "when the order does not have a credit" do
      before { subject.order.stubs(:credit).returns(nil) }

      it "raises an error" do
        expect { subject.sync_state! }.to raise_error(BankPayment::SyncStateError)
      end
    end
  end

  describe '#find_all_to_sync_state' do
    let!(:pending) { FactoryGirl.create(:bank_payment) }
    let!(:paid) { FactoryGirl.create(:paid_bank_payment) }
    let!(:rejected) { FactoryGirl.create(:rejected_bank_payment) }

    it "finds only the pending payment" do
      BankPayment.find_all_to_sync_state.should == [pending]
    end
  end
end
