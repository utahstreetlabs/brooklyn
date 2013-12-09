shared_context "dashboard layout" do
  let(:for_sale_count) { 3 }
  let(:sold_count) { 5 }
  let(:bought_count) { 6 }
end

shared_examples_for "dashboard layout action" do
  it "assigns for-sale counts" do
    assigns(:listing_counts)[:active].should == for_sale_count
  end

  it "assigns sold counts" do
    assigns(:listing_counts)[:sold].should == sold_count
  end

  it "assigns bought counts" do
    assigns(:listing_counts)[:bought].should == bought_count
  end
end

module DashboardControllerHelpers
  def act_as_dashboard_user
    me = act_as_stub_user
    Listing.stubs(:count_sold_by).with(me).once.returns({'sold' => sold_count, 'active' => for_sale_count})
    Listing.stubs(:count_bought_by).with(me).once.returns(bought_count)
    UserNotifications.stubs(:new).returns(stub_everything)
    me
  end
end
