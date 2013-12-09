require 'spec_helper'

describe CreditMailer do
  let(:user) { stub_user 'Justin Bieber' }
  let(:credit) { stub('credit', user: user, amount_remaining: 1, offer: nil) }
  let(:offer) { stub_offer }

  describe '#credit_reminder_1' do
    before { credit.stubs(:time_remaining).returns(7.days) }

    it "builds the message for a credit with an offer" do
      credit.stubs(:offer).returns(offer)
      msg = nil
      expect { msg = CreditMailer.credit_reminder_1(credit) }.not_to raise_error
      msg.should have_content(offer.descriptor)
    end

    it "builds the message for a credit without an offer" do
      credit.stubs(:offer).returns(nil)
      expect { CreditMailer.credit_reminder_1(credit) }.not_to raise_error
    end
  end

  describe '#credit_reminder_2' do
    before { credit.stubs(:time_remaining).returns(1.day) }

    it "builds the message for a credit with an offer" do
      credit.stubs(:offer).returns(offer)
      msg = nil
      expect { msg = CreditMailer.credit_reminder_2(credit) }.not_to raise_error
      msg.should have_content(offer.descriptor)
    end

    it "builds the message for a credit without an offer" do
      credit.stubs(:offer).returns(nil)
      expect { CreditMailer.credit_reminder_2(credit) }.not_to raise_error
    end
  end
end
