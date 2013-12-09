require 'spec_helper'

describe BankPayments::SyncStateJob do
  subject { BankPayments::SyncStateJob }

  describe '#work' do
    it "updates the state of a pending bank payment" do
      payment = FactoryGirl.create(:bank_payment)
      Order.any_instance.stubs(:credit).returns(stub('cleared', state: 'cleared'))
      subject.work
      payment.reload
      payment.should be_paid
    end
  end
end
