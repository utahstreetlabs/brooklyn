module TwitterIntegrationHelpers
  MAX_LOGIN_RETRIES = 2

  def popup_should_have_twitter_login
    retries = 0
    begin
      page.driver.within_window 'Sign in to Twitter' do
        page.should have_content("Username or email")
      end
    rescue Capybara::ElementNotFound
    rescue Selenium::WebDriver::Error::NoSuchWindowError
      unless retries >= MAX_LOGIN_RETRIES
        retries = retries + 1
        retry
      end
    end
  end
end

RSpec.configure do |config|
  config.include TwitterIntegrationHelpers
end
