require "spec_helper"

describe WelcomeTwo do
  let(:user) { stub_user 'Catfish Collins' }
  let(:mail) { stub('mail') }

  it "delivers a message" do
    User.expects(:find).with(user.id).returns(user)
    UserMailer.expects(:welcome_2).with(user).returns(mail)
    mail.expects(:deliver)
    WelcomeTwo.perform(user.id)
  end

  it "does not propagate an exception" do
    User.expects(:find).raises(ActiveRecord::RecordNotFound)
    UserMailer.expects(:welcome_2).never
    expect { WelcomeTwo.perform(user.id) }.not_to raise_error
  end
end
