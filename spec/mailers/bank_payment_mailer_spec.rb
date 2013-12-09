require 'spec_helper'

describe BankPaymentMailer do
  subject { FactoryGirl.create(:bank_payment) }

  it "builds a paid message for the seller" do
    expect { BankPaymentMailer.paid_for_seller(subject) }.to_not raise_error
  end

  it "builds a rejected message for the seller" do
    expect { BankPaymentMailer.rejected_for_seller(subject) }.to_not raise_error
  end
end
