require "spec_helper"

describe WelcomeThree do
  let(:user) { stub_user 'Bootsy Collins' }
  let(:mail) { stub('mail') }

  it "delivers a message" do
    User.expects(:find).with(user.id).returns(user)
    UserMailer.expects(:welcome_3).with(user).returns(mail)
    mail.expects(:deliver)
    WelcomeThree.perform(user.id)
  end

  it "does not propagate an exception" do
    User.expects(:find).raises(ActiveRecord::RecordNotFound)
    UserMailer.expects(:welcome_3).never
    expect { WelcomeThree.perform(user.id) }.not_to raise_error
  end
end
