require './acceptance/spec_helper'
require 'timecop'

feature "Login from anywhere", %q{
  As a user
  When I am visiting a page on copious
  I want to be able to login without leaving that page
} do

  background do
    @category = FactoryGirl.create(:category)
    @seller = FactoryGirl.create(:seller)
    @visitor = given_registered_user(firstname: 'Visitor', lastname: 'Visitor')
    @listing = FactoryGirl.create(:active_listing, :seller => @seller, :category => @category)
    Person.any_instance.stubs(:missing_required_network_permissions).returns([])
  end

  scenario "login without losing page on public pages", js: true do
    visit browse_for_sale_path(@category)
    expect(page).to have_css('[data-action=login]')
    find('[data-action=login]').click
    fill_in 'email', :with => @visitor.email
    fill_in 'password', :with => 'test'
    find('[data-action=auth-update]').click
    retry_expectations { expect(page).to have_no_css('[data-action=login]') }
    expect(current_path).to eq(browse_for_sale_path(@category))
  end

  scenario "login without losing page on private pages", js: true do
    visit settings_profile_path
    page.should have_no_content(@visitor.display_name)
    current_path.should == signup_path
    click_login_link
    fill_in 'email', :with => @visitor.email
    fill_in 'password', :with => 'test'
    find('[data-action=auth-update]').click
    wait_a_while_for do
      page.should have_content(@visitor.display_name)
    end
    current_path.should == settings_profile_path
  end

  scenario "login when not registered is not allowed", js: true  do
    inactive_user = FactoryGirl.create(:inactive_user, :firstname => 'Visitor', :lastname => 'Visitor')
    visit browse_for_sale_path(@category)
    page.should have_no_content(inactive_user.display_name)
    find('[data-action=login]').click
    fill_in 'email', :with => inactive_user.email
    fill_in 'password', :with => "test"
    find('[data-action=auth-update]').click
    # don't login
    wait_a_while_for do
      page.should have_no_content(inactive_user.display_name)
    end
    # show error
    page.should have_css('[data-role=login-error]')
  end

  scenario "login with invalid password shows embedded message", js: true  do
    visit browse_for_sale_path(@category)
    page.should have_no_content(@visitor.display_name)
    find('[data-action=login]').click
    fill_in 'email', :with => @visitor.email
    fill_in 'password', :with => "#{@password}extra"
    find('[data-action=auth-update]').click
    # don't login
    wait_a_while_for do
      page.should have_no_content(@visitor.display_name)
    end
    # show error
    page.should have_css('[data-role=login-error]')
  end

  scenario "hit buy now without losing page on listing page" do
    visit listing_path(@listing)
    find('[data-action=buy]').click
    wait_a_sec_for_selenium
    current_path.should == signup_path
    click_login_link
    fill_in 'email', :with => @visitor.email
    fill_in 'password', :with => 'test'
    find('[data-action=auth-update]').click
    wait_a_while_for do
      page.should have_content("Enter Your Shipping Information")
    end
  end

  def click_login_link
    find('[data-action=login_with_username][data-primary=true]').click
  end
end

feature "Update permissions", %q{
  As a user
  When I am attempting to login
  I want to update my network permissions to match required ones
} do

  include_context 'mock facebook profile'

  scenario "profile lacking required permissions connects to network" do
    given_registered_user email:     "starbuck@galactica.mil",
                          firstname: "Kara",
                          lastname:  "Thrace",
                          oauth:     OmniAuth.config.mock_auth[:facebook].merge('scope' => 'abcd')
    login_as("starbuck@galactica.mil")
    connection_should_succeed 'Facebook'
  end

  scenario "profile containing all required permissions does not connect to network" do
    given_registered_user email:     "starbuck@galactica.mil",
                          firstname: "Kara",
                          lastname:  "Thrace"
    Person.any_instance.stubs(:missing_required_network_permissions).returns([])
    login_as("starbuck@galactica.mil")
    page.should_not have_content("You are now connected to Facebook")
  end
end

feature "Login with existing Facebook user" do
  include_context 'with facebook test user'

  # Create a user initially only connected via Twitter
  let(:user) { given_registered_user(network: :twitter) }

  # Simulates a user connecting to Facebook with one set of authentication credentials
  # and then logging out.
  background do
    visit root_path
    fb_user_login fb_user, return_to: root_path
    login_as user.email
    visit dashboard_path
    connect_to 'Facebook'
    retry_expectations { connection_should_succeed 'Facebook' }
    visit logout_path
    retry_expectations { expect(current_path).to eq(root_path) }
    expect(page).to have_content("Log In")
  end

  context "update of Facebook existing auth token", js: true do
    let(:code) { 'deadbeef' }

    before do
      # When returning to Copious, this simulates the javascript library having
      # returned a different authentication token than the one originally used
      # to connect in the background block.
      Login.any_instance.stubs(:facebook_token).returns('deadbeef')
      Person.any_instance.stubs(:async_sync_connected_profiles).returns(true)
    end

    context 'when logging in with email and password' do
      scenario "valid network credentials update code" do
        Network::Facebook.expects(:parse_signed_request).returns({code: code, user_id: fb_user.id})
        Identity.any_instance.expects(:code=).with(code)
        login_as user.email
      end

      scenario "invalid network credentials are silently ignored" do
        Network::Facebook.expects(:parse_signed_request).returns(nil)
        Identity.any_instance.expects(:code=).never
        login_as user.email
        current_path.should == root_path
      end
    end

    context "when logging in by connecting with Facebook", js: true do
      scenario "with valid credentials" do
        FlyingDog::Identity.any_instance.expects(:update_from_oauth!)
        click_facebook_connect
        # make sure expectation has the opportunity to be met
        # can't use path here, cuz logged out and logged in are both +root_path+
        retry_expectations { expect(page).to have_css('.homepage_logged_in') }
      end
    end
  end

  context "auto-login of Facebook user", js: true do
    let(:listing) { given_listing }

    scenario 'succeeds when visiting listing page' do
      visit listing_path(listing)
      login_should_succeed
    end

    scenario 'succeeds after visiting settings page' do
      # Visiting settings sets the login redirect but doesn't
      # use it; we need to make sure that we clobber this redirect
      visit settings_networks_path
      expect(current_path).to eq(signup_path)
      visit listing_path(listing)
      login_should_succeed
      current_path.should == listing_path(listing)
    end

    scenario 'does not happen when visiting logged out home page' do
      visit root_path
      logging_in_modal_should_be_hidden
      current_path.should == root_path
    end

    scenario 'does not happen when not logged in to Facebook' do
      fb_logout_test_user
      visit listing_path(listing)
      logging_in_modal_should_be_hidden
      current_path.should == listing_path(listing)
    end

    def logging_in_modal_id
      'logging_in'
    end

    def logging_in_modal_should_be_hidden
      modal_should_be_hidden(logging_in_modal_id)
    end

    def logging_in_modal_should_not_exist
      modal_should_not_exist(logging_in_modal_id)
    end

    def login_should_succeed
      wait_a_while_for do
        page.should have_css("[data-user=#{user.slug}]")
      end
    end
  end
end

feature "Waiting modal" do
  include_context "with disconnected facebook test user"

  context "when clicking facebook connect via signup modal" do
    # When the auth policy is immediate, this will pop up the signup modal
    # when the facebook connect button is clicked (same as hitting a protected control).
    # For more on this, see gatekeeper.
    feature_flag('auth.policy.immediate', true)

    let(:listing) { FactoryGirl.create(:active_listing) }

    background do
      fb_user_login fb_user, return_to: root_path
      visit listing_path(listing)
      signup_modal_should_be_visible
    end

    scenario "waiting modal is visible", js: true do
      click_facebook_signup
      waiting_modal_should_be_visible
      add_copious_to_facebook
      waiting_modal_should_be_hidden
    end
  end

  def waiting_modal_id
    'waiting'
  end

  def waiting_modal_should_be_visible
    modal_should_be_visible(waiting_modal_id)
  end

  def waiting_modal_should_be_hidden
    modal_should_be_hidden(waiting_modal_id)
  end
end

feature "Login of connected Facebook user" do
  include_context 'with facebook test user'

  background do
    visit root_path
  end

  context "redirect to onboarding (for mobile)", js: true do
    scenario "succeeds for a user logged into Facebook" do
      fb_user_login fb_user, return_to: root_path
      visit facebook_connection_path
      onboarding_redirect_should_succeed
    end

    scenario "does not happen when not logged into Facebook" do
      visit facebook_connection_path
      wait_a_sec_for_selenium
      current_path.should == facebook_connection_path
    end
  end
end

feature "Facebook authenticated referrals" do
  include_context 'with facebook test user'

  context "When onboarding a connected user", js: true do
    let(:listing) { given_listing }

    background do
      given_connected_user(email: "jamespage@thezep.com",
                           firstname: "James",
                           lastname: "Page")
    end

    scenario "Redirects user to target page after short onboarding" do
      visit root_path
      fb_user_login fb_user, return_to: root_path
      visit listing_path(listing)
      onboarding_redirect_should_succeed
      complete_full_registration
      retry_expectations { expect(current_path).to eq(listing_path(listing)) }
    end
  end
end

feature "Onboard existing users", %q{
  We should be able to force old/broken users to re-onboard to
  ensure they get the full Copious feed experience.
} do

  include_context 'buyer signup'

  let(:user) { given_registered_user(needs_onboarding: true) }

  scenario "onboard and redirect to original destination", js: true do
    pending 'XXX: going to unpend this later today after we ship invite changes (2012-05-14)'
    visit_browse_page
    login_from_header_as user.email
    wait_a_sec_for_selenium
    should_display_revamp_flash
    proceed_through_onboarding
    should_be_on_browse_page
  end

  def visit_browse_page
    visit browse_for_sale_path
  end

  def should_display_revamp_flash
    page.should have_flash_message(:notice, 'controllers.sessions.re_onboarding')
  end

  def should_be_on_browse_page
    current_path.should == browse_for_sale_path
  end
end
