require "spec_helper"

describe WelcomeFive do
  let(:user) { stub_user 'Bootsy Collins' }
  let(:mail) { stub('mail') }

  it "delivers a message when the user has not invited more than 10 friends" do
    User.expects(:find).with(user.id).returns(user)
    user.expects(:direct_invite_count).returns(10)
    UserMailer.expects(:welcome_5).with(user).returns(mail)
    mail.expects(:deliver)
    WelcomeFive.perform(user.id)
  end


  it "does not deliver a message when the user has invited more than 10 friends" do
    User.expects(:find).with(user.id).returns(user)
    user.expects(:direct_invite_count).returns(11)
    UserMailer.expects(:welcome_5).never
    WelcomeFive.perform(user.id)
  end

  it "does not propagate an exception" do
    User.expects(:find).raises(ActiveRecord::RecordNotFound)
    UserMailer.expects(:welcome_5).never
    expect { WelcomeFive.perform(user.id) }.not_to raise_error
  end
end
