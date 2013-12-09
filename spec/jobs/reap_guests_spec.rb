require "spec_helper"
require 'timecop'

describe ReapGuests do
  let(:guest) { FactoryGirl.create(:guest_user) }
  let(:listing) { FactoryGirl.create(:inactive_listing, seller: guest) }

  before do
    Anchor::User.expects(:destroy!).never
    Lagunitas::User.expects(:destroy!).never
    Pyramid::User.expects(:destroy!).never
    Profile.expects(:find_all_for_person!).never
  end 

  it "should delete guest users older than 7 days" do
    guest.should be
    listing.should be
    Timecop.travel(Time.zone.now + User.guest_user_lifetime + 1.minute) do
      ReapGuests.perform
      lambda { guest.reload }.should raise_error(ActiveRecord::RecordNotFound)
      lambda { listing.reload }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
