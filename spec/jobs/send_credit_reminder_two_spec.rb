require "spec_helper"

describe SendCreditReminderTwo do
  let(:credit) { stub('credit', id: '1') } 
  let(:mail) { stub('mail') }

  it "delivers a message when the user has unused credit" do
    Credit.expects(:find).with(credit.id).returns(credit)
    credit.expects(:used?).returns(false)
    CreditMailer.expects(:credit_reminder_2).with(credit).returns(mail)
    mail.expects(:deliver)
    SendCreditReminderTwo.perform(credit.id)
  end

  it "does not deliver a message when the user has used the full credit amount" do
    Credit.expects(:find).with(credit.id).returns(credit)
    credit.expects(:used?).returns(true)
    CreditMailer.expects(:credit_reminder_2).never
    SendCreditReminderTwo.perform(credit.id)
  end

  it "does not propagate an exception" do
    Credit.expects(:find).raises(ActiveRecord::RecordNotFound)
    CreditMailer.expects(:credit_reminder_2).never
    expect { SendCreditReminderTwo.perform(credit.id) }.not_to raise_error
  end
end
