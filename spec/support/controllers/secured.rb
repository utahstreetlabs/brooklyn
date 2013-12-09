shared_context "for an anonymous_user" do
  before { act_as(nil) }
end

shared_examples "secured against anonymous users" do
  include_context "for an anonymous_user"

  it "is redirected to the signup page" do
    response.should be_redirected_to_auth_page
  end
end

shared_examples "xhr secured against anonymous users" do
  include_context "for an anonymous_user"

  it "is not authorized" do
    response.should be_jsend_error
    response.should be_jsend_unauthorized
  end
end

shared_context "for a logged-in user" do |stubs = {}|
  before { act_as_stub_user(stubs: stubs) }
end

shared_context "user is logged in" do |stubs = {}|
  let!(:user) { act_as_stub_user(stubs: stubs) }
end

shared_examples "secured against rfbs" do
  include_context "for a logged-in user"

  it "is redirected to the home page" do
    response.should be_redirected_to_home_page
  end
end

shared_examples "xhr secured against rfbs" do
  include_context "for a logged-in user"

  it "is not authorized" do
    response.should be_jsend_error
    response.should be_jsend_unauthorized
  end
end

shared_context "for an admin user" do
  before { act_as_stub_user(admin: true) }
end

