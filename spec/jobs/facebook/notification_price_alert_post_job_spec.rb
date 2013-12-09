require 'spec_helper'

describe Facebook::NotificationPriceAlertPostJob do
  subject { Facebook::NotificationPriceAlertPostJob }

  let(:user) { FactoryGirl.create(:registered_user) }
  let(:profile) do
    stub_network_profile("#{user.name}-facebook", :facebook, name: user.name, person_id: user.person.id)
  end
  let(:listing) { FactoryGirl.create(:active_listing) }

  before do
    User.any_instance.stubs(:for_network).with(Network::Facebook).returns(profile)
    Rubicon::FacebookProfile.stubs(:find).with(profile.id, is_a(Hash)).returns(profile)
  end

  context "when the user has liked a listing" do
    before do
      Listing.stubs(:liked_by_ids).with(user, is_a(Hash)).returns([listing.id])
      # no saves by default
    end

    it "succeeds" do
      subject.expects(:track_usage)
      subject.expects(:post_notification).with(profile, listing, is_a(Integer), is_a(String))
      subject.work(profile.id)
    end
  end

  context "when the user has saved a listing" do
    before do
      Listing.stubs(:liked_by_ids).with(user, is_a(Hash)).returns([])
      user.save_listing_to_collections(listing, [user.collections.first])
    end

    it "succeeds" do
      subject.expects(:track_usage)
      subject.expects(:post_notification).with(profile, listing, is_a(Integer), is_a(String))
      subject.work(profile.id)
    end
  end

  context "when the user has not interacted with any listings" do
    before do
      Listing.stubs(:liked_by_ids).with(user, is_a(Hash)).returns([])
      # no saves by default
    end

    context "and there is a trending listing" do
      before do
        Listing.stubs(:find_trending_ids).returns([listing.id])
      end

      it "succeeds" do
        subject.expects(:track_usage)
        subject.expects(:post_notification).with(profile, listing, is_a(Integer), is_a(String))
        subject.work(profile.id)
      end
    end

    context "and there are not trending listings" do
      it "does nothing" do
        subject.expects(:track_usage).never
        subject.expects(:post_notification).never
        subject.work(profile.id)
      end
    end
  end
end
