module WindowHelpers
  def popup_window_open?
    page.driver.browser.window_handles.count > 1
  end

  def within_last_popup_window(&block)
    within_window(page.driver.browser.window_handles.last, &block)
  end

  def close_all_popup_windows
    if (Capybara.current_driver == Capybara.javascript_driver) && popup_window_open?
      # Closes all windows except the main browser window
      main_id = page.driver.browser.window_handles[0]
      begin
        (1..(page.driver.browser.window_handles.count-1)).each do |i|
          begin
            # Never ever close the main browser window here
            unless page.driver.browser.window_handles[i] == main_id
              page.driver.browser.switch_to.window(page.driver.browser.window_handles[i])
              page.driver.browser.close
            end
          rescue Selenium::WebDriver::Error::NoSuchWindowError
            # Window likely closed after we detected it was open; just fall through
          end
        end
      ensure
        page.driver.browser.switch_to.window(main_id)
      end
    end
  end
end

RSpec.configure do |config|
  config.include WindowHelpers
end
