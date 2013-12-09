shared_context "not connected to facebook" do
  before { controller.current_user.person.expects(:connected_to?).with(:facebook).returns(false) }
end

shared_examples "not available to those not connected to facebook" do
  include_context "not connected to facebook"

  it "is not authorized" do
    response.should be_redirected_to_home_page
  end
end

shared_examples "xhr not available to those not connected to facebook" do
  include_context "not connected to facebook"

  it "is not authorized" do
    response.should be_jsend_error
    response.should be_jsend_unauthorized
  end
end

shared_context "connected to facebook" do
  before { controller.current_user.person.expects(:connected_to?).with(:facebook).returns(true) }
end
