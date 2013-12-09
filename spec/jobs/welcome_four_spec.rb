require "spec_helper"

describe WelcomeFour do
  let(:user) { stub_user 'Bootsy Collins' }
  let(:mail) { stub('mail') }

  it "delivers a message when the user has not published a listing" do
    User.expects(:find).with(user.id).returns(user)
    user.expects(:published_listing_count).returns(0)
    UserMailer.expects(:welcome_4).with(user).returns(mail)
    mail.expects(:deliver)
    WelcomeFour.perform(user.id)
  end


  it "does not deliver a message when the user has published a listing" do
    User.expects(:find).with(user.id).returns(user)
    user.expects(:published_listing_count).returns(1)
    UserMailer.expects(:welcome_4).never
    WelcomeFour.perform(user.id)
  end

  it "does not propagate an exception" do
    User.expects(:find).raises(ActiveRecord::RecordNotFound)
    UserMailer.expects(:welcome_4).never
    expect { WelcomeFour.perform(user.id) }.not_to raise_error
  end
end
