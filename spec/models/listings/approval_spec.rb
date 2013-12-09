require 'spec_helper'

describe Listings::Approval do
  subject { Listing.new }

  describe '.approve!' do
    subject { FactoryGirl.create(:incomplete_listing) }

    it 'persists the approval' do
      subject.approve!
      subject.approved.should be_true
      subject.approved_at.should be
      subject.should_not be_changed
    end

    it 'does not persist the approval' do
      subject.approve!(persist: false)
      subject.approved.should be_true
      subject.approved_at.should be
      subject.should be_changed
    end

    it 'enqueues after job' do
      Listings::AfterApprovalJob.expects(:enqueue).with(subject.id)
      subject.approve!
    end
  end

  describe '.disapprove!' do
    subject { FactoryGirl.create(:incomplete_listing) }

    it 'persists the disapproval' do
      subject.disapprove!
      subject.approved.should be_false
      subject.approved_at.should be
      subject.should_not be_changed
    end

    it 'does not persist the disapproval' do
      subject.disapprove!(persist: false)
      subject.approved.should be_false
      subject.approved_at.should be
      subject.should be_changed
    end

    it 'enqueues after job' do
      Listings::AfterDisapprovalJob.expects(:enqueue).with(subject.id)
      subject.disapprove!
    end
  end

  describe '#available_for_approval' do
    it 'returns only active listings' do
      l1 = FactoryGirl.create(:incomplete_listing)
      l2 = FactoryGirl.create(:active_listing)
      Listing.available_for_approval.should == [l2]
    end

    it 'returns only unapproved listings' do
      l1 = FactoryGirl.create(:active_listing)
      l1.approve!
      l2 = FactoryGirl.create(:active_listing)
      l2.disapprove!
      l3 = FactoryGirl.create(:active_listing)
      Listing.available_for_approval.should == [l3]
    end

    it "returns only seller's listing" do
      l1 = FactoryGirl.create(:active_listing)
      l2 = FactoryGirl.create(:active_listing)
      Listing.available_for_approval(seller_id: l2.seller_id).should == [l2]
    end
  end
end
