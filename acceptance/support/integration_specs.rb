require "capybara/rspec"

DEFAULT_PASSWORD = "test"

module AcceptanceHelper
  attr_accessor :current_user

  def retry_with_sleep(max_retries=3, sleep_time=0.1)
    retries = 0
    begin
      yield
    rescue Exception => e
      if retries < max_retries
        retries += 1
        sleep(sleep_time)
        retry
      else
        raise e
      end
    end
  end

  def set_fb_cookie(key, value)
    Capybara.current_session.driver.execute_script <<-JS
      document.cookie = "#{key}=#{value}";
    JS
  end

  def login_as(email, options={})
    logout if options[:logout]
    me = User.find_by_email(email)
    unless me
      attrs = {email: email, network: options[:network], name: options[:name]}
      attrs[:superuser] = options[:superuser] || false
      attrs[:admin] = options[:superuser] || options[:admin] || false
      me = given_registered_user(attrs)
    end
    visit login_path unless options[:on_current_page]
    fill_in "email", :with => email
    fill_in "password", :with => DEFAULT_PASSWORD
    uncheck 'remember_me_unpw' if options[:dont_remember_me]
    click_button "Log in"
    self.current_user = me
  end

  def login_from_header_as(email, options = {})
    click_link 'Log in'
    login_as user.email, on_current_page: true
  end

  def clear_all_notifications(user = nil)
    user ||= current_user
    Lagunitas::Notification.delete_all_for_user(user.id)
  end

  def suppress_signup_follows
    User.any_instance.stubs(:to_follow_during_signup).returns
  end

  shared_context 'suppress signup follows' do
    before { suppress_signup_follows }
  end

  def logout
    visit logout_path
  end

  def wait_for(secs)
    sleep secs
  end

  # Open an accordion section
  def open_section(label)
    find(:xpath, %Q(//.[@role="tab"][contains(., "#{label}")])).click
  end

  def wait_a_while_for
    default_wait = Capybara.default_wait_time
    Capybara.default_wait_time = 30
    begin
      yield
    ensure
      Capybara.default_wait_time = default_wait
    end
  end

  def with_obsolete_element_retry
    # note that this exception has been renamed to Selenium::WebDriver::Error::StaleElementReferenceError.
    # wait_for_dom_to_update may be a better solution.
    begin
      yield
    rescue Selenium::WebDriver::Error::ObsoleteElementError
      # race condition can make this happen - just try again:
      # http://qastuffs.blogspot.com/2010/12/webdriver-error-element-is-no-longer.html
      yield
    end
  end

  def wait_for_dom_to_update
    # after executing an ajax request that replaces some html that had previously been processed and cached by selenium
    # and/or webdriver, we need to wait a little while to make sure everything settles down and comes back to normal.
    # this can be used instead of #with_obsolete_element_retry.
    sleep 1
  end

  def wait_for_gatekeeper_controls_protected
    retry_expectations do
      page.evaluate_script('window.Copious.gatekeeper.controlsProtected').should be_true
    end
  end

  def fixture(file)
    "#{Rails.root}/spec/fixtures/#{file}"
  end

  def bootstrap_modal_should(matcher)
    within('.modal', visible: true) { expect(page).to matcher }
  end

  def bootstrap_modal_should_not(matcher)
    within('.modal', visible: true) { expect(page).to matcher }
  end

  # there's a known [soulcrushing, happinessdestroying] issue with selenium
  # that causes xpath failures with shocking regularity:
  # http://code.google.com/p/selenium/issues/detail?id=2287
  # http://code.google.com/p/selenium/issues/detail?id=2099
  #
  # sleep seems to fix it, so, do that.
  def wait_a_sec_for_selenium
    sleep 1 if Capybara.current_driver == :selenium_firefox
  end

  def i_should_see(page)
    current_path.should == send("#{page}_path")
  end

  # use javascript to explicitly show an element
  # this is often needed with hover elements, because capybara +
  # selenium doesn't have good support for simulating hover events
  def simulate_hover(element)
    page.execute_script("$('#{element}').show()")
    wait_a_sec_for_selenium
  end

  def with_javascript_driver(&block)
    driver = Capybara.current_driver
    Capybara.current_driver = Capybara.javascript_driver
    yield
    Capybara.current_driver = driver
  end

  RETRY_EXPECTATIONS_SLEEP_TIME = 0.1
  RETRIES_PER_SECOND = (1 / RETRY_EXPECTATIONS_SLEEP_TIME).to_i

  def retry_expectations(time = 3)
    retry_count = 0
    begin
      yield
    rescue RSpec::Expectations::ExpectationNotMetError => e
      if retry_count < RETRIES_PER_SECOND * time
        retry_count += 1
        sleep RETRY_EXPECTATIONS_SLEEP_TIME
        retry
      else
        raise e
      end
    end
  end

  def accept_alert
    page.driver.browser.switch_to.alert.accept
  end
end

# Define methods here that will get added to Capybara::Session.
# This lets us do things like:
#
#   page.users.each { |node| ... }
#   page.should have(3).users
#
module NamedSelectors
  def product_cards
    all '[data-card=product]'
  end
  alias_method :product_card, :product_cards

  def tag_cards
    all '.tag-container'
  end
  alias_method :tag_card, :tag_cards

  def user_cards
    all '[data-card=user]'
  end
  alias_method :user_card, :user_cards

  def interest_cards
    all '.interest-card'
  end
  alias_method :interest_card, :interest_cards

  def featured_product_cards
    # the product carousel clones product cards, which makes extras. filter those out.
    all "ul:not(.cloned) > [data-role=product-card]"
  end
  alias_method :featured_product_card, :featured_product_cards

  def collection_cards
    all '[data-card=collection]'
  end
  alias_method :collection_card, :collection_cards

  def user_strips
    all '[data-role=user-strip]'
  end
  alias_method :user_strip, :user_strips

  def user_feedbacks
    all '[data-role=user-feedback]'
  end
  alias_method :user_feedback, :user_feedbacks

  def credits
    all('.credit')
  end

  def network_stories
    all('.network-story')
  end
  alias_method :network_story, :network_stories

  def listing_photos
    all '[data-role=listing-photo]'
  end
  alias_method :listing_photo, :listing_photos
end

class Capybara::Session
  include NamedSelectors
end

class Capybara::Node::Element
  include NamedSelectors
end

# This patch attempts to fix a race condition in the selenium web driver
# Reference: https://code.google.com/p/selenium/issues/detail?id=2099
class Capybara::Selenium::Driver
  def find(selector)
    browser.find_elements(:xpath, selector).map { |node| Capybara::Selenium::Node.new(self, node) }
  rescue Selenium::WebDriver::Error::InvalidSelectorError => e
    e.message =~ /nsIDOMXPathEvaluator.createNSResolver/ ? retry : raise
  end
end

RSpec.configure do |config|
  config.include AcceptanceHelper
end
