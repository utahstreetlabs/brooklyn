require 'spec_helper'

describe Admin::ListingsController do
  let(:listing) { stub('listing', id: 192) }

  before do
    act_as_stub_user(admin: true)
    Listing.expects(:find).with(listing.id.to_s).returns(listing)
  end

  it "reactivates a listing" do
    listing.stubs(:can_reactivate?).returns(true)
    listing.expects(:reactivate!)
    put :reactivate, id: listing.id
    response.should redirect_to(admin_listing_path(listing.id))
  end

  it "does not reactivate a listing in the wrong state" do
    listing.stubs(:can_reactivate?).returns(false)
    listing.expects(:reactivatel!).never
    put :reactivate, id: listing.id
    response.should redirect_to(admin_listing_path(listing.id))
  end

  it "cancels a listing" do
    listing.stubs(:can_cancel?).returns(true)
    listing.expects(:cancel!)
    put :cancel, id: listing.id
    response.should redirect_to(admin_listing_path(listing.id))
  end

  it "does not cancel a listing in the wrong state" do
    listing.stubs(:can_cancel?).returns(false)
    listing.expects(:cancel!).never
    put :cancel, id: listing.id
    response.should redirect_to(admin_listing_path(listing.id))
  end

  it "suspends a listing" do
    listing.stubs(:can_suspend?).returns(true)
    listing.expects(:suspend!)
    put :suspend, id: listing.id
    response.should redirect_to(admin_listing_path(listing.id))
  end

  it "does not suspend a listing in the wrong state" do
    listing.stubs(:can_suspend?).returns(false)
    listing.expects(:suspend!).never
    put :suspend, id: listing.id
    response.should redirect_to(admin_listing_path(listing.id))
  end
end
