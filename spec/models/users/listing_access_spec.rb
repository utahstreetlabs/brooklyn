require 'spec_helper'

describe Users::ListingAccess do
  subject { FactoryGirl.create(:guest_user) }

  context 'with full listing access' do
    before do
      subject.update_attributes!(listing_access: 1)
      subject.reload
    end

    its(:full_listing_access?)         { should be_true }
    its(:no_listing_access?)           { should be_false }
    its(:limited_listing_access?)      { should be_false }
    its(:undetermined_listing_access?) { should be_false }
  end

  context 'with no listing access' do
    before do
      subject.update_attributes!(listing_access: -1)
      subject.reload
    end

    its(:full_listing_access?)         { should be_false }
    its(:no_listing_access?)           { should be_true }
    its(:limited_listing_access?)      { should be_false }
    its(:undetermined_listing_access?) { should be_false }
  end

  context 'with limited listing access' do
    before do
      subject.update_attributes!(listing_access: 0)
      subject.reload
    end

    its(:full_listing_access?)         { should be_false }
    its(:no_listing_access?)           { should be_false }
    its(:limited_listing_access?)      { should be_true }
    its(:undetermined_listing_access?) { should be_false }
  end

  context 'with undetermined listing access' do
    before do
      subject.update_attributes!(listing_access: nil)
      subject.reload
    end

    its(:full_listing_access?)         { should be_false }
    its(:no_listing_access?)           { should be_false }
    its(:limited_listing_access?)      { should be_false }
    its(:undetermined_listing_access?) { should be_true }
  end

  describe '.listings_available_for_approval' do
    subject { FactoryGirl.create(:registered_user) }

    it "returns only the user's listings" do
      l1 = FactoryGirl.create(:active_listing, seller: subject)
      l2 = FactoryGirl.create(:active_listing)
      subject.listings_available_for_approval.should == [l1]
    end
  end

  describe '.clear_bullpen_if_necessary' do
    subject { FactoryGirl.create(:registered_user) }

    it 'does nothing if access was not changed' do
      subject.expects(:approve_all_available_listings).never
      subject.expects(:disapprove_all_available_listings).never
      subject.clear_bullpen_if_necessary
    end

    it 'does nothing if access is limited' do
      subject.expects(:approve_all_available_listings).never
      subject.expects(:disapprove_all_available_listings).never
      subject.listing_access = User::ListingAccess::LIMITED
      subject.clear_bullpen_if_necessary
    end

    it 'does nothing if access is undetermined' do
      subject.update_attributes!(listing_access: User::ListingAccess::FULL) # now it can be dirtied
      subject.expects(:approve_all_available_listings).never
      subject.expects(:disapprove_all_available_listings).never
      subject.listing_access = nil
      subject.clear_bullpen_if_necessary
    end

    it 'approves all listings if access is full' do
      subject.expects(:approve_all_available_listings)
      subject.expects(:disapprove_all_available_listings).never
      subject.listing_access = User::ListingAccess::FULL
      subject.clear_bullpen_if_necessary
    end

    it 'disapproves all listings if access is none' do
      subject.expects(:approve_all_available_listings).never
      subject.expects(:disapprove_all_available_listings)
      subject.listing_access = User::ListingAccess::NONE
      subject.clear_bullpen_if_necessary
    end
  end
end
