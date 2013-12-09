module FacebookIntegrationHelpers
  def create_fb_user(options = {})
    retry_with_sleep(5) { Brooklyn::GraphApi.create_test_user(options.merge(installed: false)) }
  end

  def destroy_fb_user
    retry_with_sleep(5) { Brooklyn::GraphApi.destroy_test_user() }
  end

  def get_fb_user(options = {})
    retry_with_sleep(5) { Brooklyn::GraphApi.get_test_user(options.merge(installed: true)) }
  end

  shared_context "with facebook test user" do |args = {}|
    let!(:fb_user) { get_fb_user(args) }

    # can't use a fb user if omniauth is in test mode!
    before { OmniAuth.config.test_mode = false }

    after(:each) do
      fb_logout_test_user
      destroy_fb_user
      OmniAuth.config.test_mode = true
    end

    # NOTE: if you use this method (and js: true) you MUST initialize selenium
    # first -- doing a "visit root_path" first is fine -- otherwise you'll get
    # webdriver errors.
    def fb_user_login(user = fb_user, options = {})
      fb_login_test_user(user, options)
    end
  end

  # A disconnected test user is one which does not already have the Copious app
  # installed for that account.
  shared_context "with disconnected facebook test user" do |args = {}|
    let!(:fb_user) { create_fb_user(args) }

    # can't use a fb user if omniauth is in test mode!
    before { OmniAuth.config.test_mode = false }

    after(:each) do
      fb_logout_test_user
      destroy_fb_user
      OmniAuth.config.test_mode = true
    end

    def fb_user_login(user = fb_user, options = {})
      fb_login_test_user(user, options)
    end
  end

  def visiting_facebook_profile?(page)
    page.has_css?('#login_form') ? false : true
  end

  MAX_FACEBOOK_RETRIES = 2

  def add_copious_to_facebook(options = {})
    # 03/28/2013: Facebook started A/B testing permissions dialogs.  There's currently two variants,
    # with different titles and button names.  In one variant, there's a single dialog and in the other
    # there's two dialogs (the old "extended permissions" are in the second).
    accept_basic_gdp_facebook_permissions(options)
  end

  def accept_basic_gdp_facebook_permissions(options = {})
    return unless popup_window_open?
    retries = 0
    gdp_options = {
      variant: :single_dialog,
      accept_button: 'Log In with Facebook'
    }
    begin
      within_last_popup_window do
        click_button(gdp_options[:accept_button])
      end
      accept_extended_gdp_facebook_permissions(options) if gdp_options[:variant] == :multi_dialog
    rescue Selenium::WebDriver::Error::NoSuchWindowError, Capybara::ElementNotFound
      # Retry in the event that the window hasn't popped up yet.
      if retries >= MAX_FACEBOOK_RETRIES
        if gdp_options[:variant] == :single_dialog
          # Try the secondary dialog configuration
          retries = 0
          gdp_options[:variant] = :multi_dialog
          gdp_options[:accept_button] = 'Okay'
          retry
        end
      else
        retries = retries + 1
        wait_a_sec_for_selenium
        retry
      end
    end
  end

  def accept_extended_gdp_facebook_permissions(options = {})
    return unless popup_window_open?
    retries = 0
    gdp_options = {
      accept_button: 'Okay'
    }
    begin
      within_last_popup_window do
        click_button(gdp_options[:accept_button])
      end
    rescue Selenium::WebDriver::Error::NoSuchWindowError, Capybara::ElementNotFound
      # Retry in the event that the window hasn't popped up yet.
      unless retries >= MAX_FACEBOOK_RETRIES
        retries = retries + 1
        wait_a_sec_for_selenium
        retry
      end
    end
  end

  def accept_insane_gdp_facebook_permissions(options = {})
    retries = 0
    gdp_options = {
      variant: :first,
      accept_button: 'Allow'
    }
    begin
      return unless popup_window_open?
      within_last_popup_window do
        click_button(gdp_options[:accept_button])
      end
    rescue Selenium::WebDriver::Error::NoSuchWindowError, Capybara::ElementNotFound
      # Retry in the event that the window hasn't popped up yet.
      if retries >= MAX_FACEBOOK_RETRIES
        if gdp_options[:variant] == :first
          # Try the secondary dialog configuration
          retries = 0
          gdp_options[:variant] = :second
          gdp_options[:accept_button] = 'Add to Facebook'
          retry
        end
      else
        retries = retries + 1
        wait_a_sec_for_selenium
        retry
      end
    end
  end

  def login_to_facebook(user, options = {})
    retries = 0
    begin
      page.driver.within_window 'Log In | Facebook' do
        fill_in 'email', with: user.email
        fill_in 'pass', with: user.password
        click_button 'Log In'
      end
    rescue Selenium::WebDriver::Error::NoSuchWindowError, Capybara::ElementNotFound
      # Retry in the event that the window hasn't popped up yet.
      unless retries >= MAX_FACEBOOK_RETRIES
        retries = retries + 1
        retry
      end
    end
  end

  def accept_extended_facebook_permissions(options = {})
    within_frame(page.find(:xpath, "//iframe[@class='FB_UI_Dialog']")[:id]) do
      click_button 'Allow'
      wait_a_sec_for_selenium
    end
  end

  def deny_extended_facebook_permissions(options = {})
    within_frame(page.find(:xpath, "//iframe[@class='FB_UI_Dialog']")[:id]) do
      click_button 'Skip'
      wait_a_sec_for_selenium
    end
  end

  def fb_logout_test_user
    # calling FB.logout on our side would require some smart async handling that we
    # don't have, so just wipe all cookies from facebook
    # also, capybara by default will do this for us on our own stuff, but not if the
    # last place we visit is fb, so get back to home after
    visit 'http://facebook.com'
    Capybara.reset_sessions!
    visit root_path
  end

  # Logs a test user into Facebook
  # @option return_to [String] path that should be visited after logging in
  def fb_login_test_user(test_user, options = {})
    return_to = options[:return_to]
    return_to ||= begin
      wait_a_sec_for_selenium
      page.current_path
    end
    begin
      visit test_user.login_url
      for i in 0..3
        break if visiting_facebook_profile?(page)
        wait_for(3)
        Rails.logger.debug "Not visiting Facebook profile page, trying again (i=>#{i})."
        visit test_user.login_url
      end
    rescue Selenium::WebDriver::Error::WebDriverError => e
      Rails.logger.debug "Caught WebDriverError, msg => #{e.message}"
      # Fall through and just visit current page.
    end
    visit return_to
    retry_expectations { expect(page.current_path).to eq(return_to) }
  end

  MAX_LOGIN_RETRIES = 2

  def popup_should_have_facebook_login
    retries = 0
    begin
      page.driver.within_window 'Log In | Facebook' do
        page.should have_content("Facebook Login")
      end
    rescue Capybara::ElementNotFound
    rescue Selenium::WebDriver::Error::NoSuchWindowError
      unless retries >= MAX_LOGIN_RETRIES
        retries = retries + 1
        retry
      end
    end
  end

  def given_eligible_for_timeline(allow=true)
    Person.any_instance.stubs(:eligible_for_facebook_timeline?).returns(allow)
  end

  def given_no_timeline_permission
    Network::Facebook.stubs(:update_preferences)
    Mogli::User.any_instance.stubs(:has_permission?).with(:publish_actions).returns(false)
    Rubicon::FacebookProfile.any_instance.stubs(:missing_live_permissions).with([:publish_actions]).
      returns([:publish_actions])
  end

  def given_timeline_permission
    Mogli::User.any_instance.stubs(:has_permission?).with(:publish_actions).returns(true)
    Rubicon::FacebookProfile.any_instance.stubs(:missing_live_permissions).with([:publish_actions]).returns([])
  end

  def stub_graph_api
    stub_request(:get, /graph.facebook.com:443\/me/).
      to_return(status: 200, headers: {'Content-Length' => 354, 'Content-Type' => 'text/javascript; charset=UTF-8'}, body: '{"id":"100002801027112","name":"Patricia Ambhjajbgaab Alisonsky","first_name":"Patricia","middle_name":"Ambhjajbgaab","last_name":"Alisonsky","link":"http:\/\/www.facebook.com\/profile.php?id=100002801027112","gender":"female","email":"ccyrdqr_alisonsky_1313425336\u0040tfbnw.net","timezone":-4,"locale":"en_US","updated_time":"2011-08-15T16:22:22+0000"}')
    stub_request(:get, /graph.facebook.com:443\/100002801027112\/accounts/).
      to_return(status: 200, headers: {'Content-Length' => 100, 'Content-Type' => 'text/javascript; charset=UTF-8'}, :body => '{"data":[{"name":"Ham Socks","category":"Community","id":"183139418423311","access_token":"78123"}]}')
    Mogli::User.any_instance.stubs(:has_permission?).returns(true)
  end

  def stub_post_facebook_invite
    stub_request(:post, /graph.facebook.com\/+\d*\/feed/).
      to_return(status: 200, headers: {'Content-Length' => 0, 'Content-Type' => 'text/javascript; charset=UTF-8'}, :body => '')
  end

  shared_context "stubbed graph api" do
    before { stub_graph_api }
  end
end

RSpec.configure do |config|
  config.include FacebookIntegrationHelpers
end
