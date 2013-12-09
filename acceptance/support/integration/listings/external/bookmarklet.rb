module Listings::External::BookmarkletHelpers
  def setup_bookmarklet_test
    @category = FactoryGirl.create(:category)
    # Capybara doesn't seem to like finding window handles that include encoded
    # html entities, so we just search for the partial string without the entity.
    @post_title = I18n.t('listings.bookmarklet.show.title_html').gsub(/&\w{1,10};/,'')
    @complete_title = I18n.t('listings.external.bookmarklet.complete.title')
    @external_new_title = I18n.t('listings.external.new.title')
    load_bookmarklet_test_page
  end

  def load_bookmarklet_test_page
    visit "http://#{s3_www_host}/bookmarklet.html"
    # Unless we wait for images to be downloaded, the test won't work correctly.
    retry_expectations { expect(page).to have_css "img:nth-child(4)" }
    load_bookmarklet_javascript
  end

  def load_bookmarklet_javascript
    script = <<JS
javascript:(function(d) {
  var e=d.createElement('script');
  e.setAttribute('type','text/javascript');
  e.setAttribute('charset','UTF-8');
  e.setAttribute('src','#{Capybara.app_host}/assets/bookmarklet.js');
  d.body.appendChild(e);
})(document);void(0)
JS
    page.execute_script(script)
  end

  def select_overlay_image(num)
    # Normally the link is only visible due to a mouseover event; we just make
    # it visible by having Capybara execute a script.
    page.execute_script("$('[data-role=\"image-choice\"]:nth-child(#{num}) a').trigger('mouseover')")
    page.find("[data-role='image-choice']:nth-child(#{num}) a").click
  end

  MAX_BOOKMARKLET_POPUP_RETRIES = 5

  def retry_for_bookmarklet_popup_window(&block)
    retries = 0
    begin
      yield
    rescue Selenium::WebDriver::Error::NoSuchWindowError, Capybara::ElementNotFound
      unless retries >= MAX_BOOKMARKLET_POPUP_RETRIES
        retries = retries + 1
        wait_a_sec_for_selenium
        retry
      end
    end
  end

  def wait_for_login_popup
    retry_for_bookmarklet_popup_window do
      within_last_popup_window do
        find("#new_login", visible: true)
      end
    end
  end

  def wait_for_complete_window
    retry_for_bookmarklet_popup_window do
      within_last_popup_window do
        page.has_css?("[data-role='external-listing'] a").should be_true
      end
    end
  end

  def wait_for_add_listing_popup
    retry_for_bookmarklet_popup_window do
      within_window @external_new_title do
        find("#listing_new", visible: true)
      end
    end
  end

  def login_user_within_popup
    within_last_popup_window do
      login_as "starbuck@galactica.mil", on_current_page: true
    end
  end

  def add_bookmarklet_external_listing
    within_window @external_new_title do
      find('#listing_price').value.should == "22.00"
      find('#listing_title').value.should == "Copious Bookmarklet Test"
      select(@category.name, from: 'listing[category_slug]') if @category
      fill_in('listing[description]', with: 'A fine ham, this one is.')
      find('#listing_save').click
      wait_a_sec_for_selenium
    end
  end

  def save_external_listing_to_collection
    retry_for_bookmarklet_popup_window do
      within_window @external_new_title do
        select_from_collection_selector(current_user.collections.first.slug)
        submit_bookmarklet_external_listing_collection_form
      end
    end
  end

  def submit_bookmarklet_external_listing_collection_form
    find('input[type=submit]').click
  end

  def bookmarklet_external_listing_post_should_succeed
    retry_for_bookmarklet_popup_window do
      within_window @complete_title do
        page.has_css?("[data-role='external-listing'] a").should be_true
        page.driver.browser.close
      end
    end
  end

  def s3_www_host
    "utahstreetlabs-dev-www.s3-website-us-east-1.amazonaws.com"
  end

  def bookmarklet_overlay_should_have_choices(count)
    page.has_css?("[data-role='image-choice']:nth-child(#{count})", visible: true).should be_true
  end
end

RSpec.configure do |config|
  config.include Listings::External::BookmarkletHelpers
end
