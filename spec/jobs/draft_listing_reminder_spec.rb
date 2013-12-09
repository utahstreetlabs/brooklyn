require "spec_helper"

describe DraftListingReminder do
  let(:user) { stub_user 'Ben Folds' }
  let(:draft) { stub_listing 'Tricorn Hat' }
  let(:mail) { stub('mail') }

  it "delivers a message when the user has a draft listing" do
    User.expects(:find).with(user.id).returns(user)
    user.expects(:draft_listings).returns([draft])
    UserMailer.expects(:draft_listing_reminder).with(user, draft).returns(mail)
    mail.expects(:deliver)
    DraftListingReminder.perform(user.id)
  end

  it "does not deliver a message when the user does not have a draft listing" do
    User.expects(:find).with(user.id).returns(user)
    user.expects(:draft_listings).returns([])
    UserMailer.expects(:draft_listing_reminder).never
    DraftListingReminder.perform(user.id)
  end

  it "does not propagate an exception" do
    User.expects(:find).raises(ActiveRecord::RecordNotFound)
    UserMailer.expects(:draft_listing_reminder).never
    expect { DraftListingReminder.perform(user.id) }.not_to raise_error
  end
end
