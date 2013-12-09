require 'spec_helper'

describe SellerPayment do
  context "a pending payment" do
    subject { FactoryGirl.create(:bank_payment) }

    it "sets timestamp and calls callbacks when transitioning to paid" do
      SellerPayments::AfterPaidJob.expects(:enqueue).with(subject.id)
      subject.pay!
      subject.reload
      subject.should be_paid
      subject.paid_at.should be
    end

    it "sets timestamp and calls callbacks when transitioning to rejected" do
      SellerPayments::AfterRejectedJob.expects(:enqueue).with(subject.id)
      subject.reject!
      subject.reload
      subject.should be_rejected
      subject.rejected_at.should be
    end

    it "sets timestamp when transitioning to canceled" do
      subject.cancel!
      subject.reload
      subject.should be_canceled
      subject.canceled_at.should be
    end
  end
end
