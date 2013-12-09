module ScrollingIntegrationHelpers
  def scroll_window_to_middle
    page.execute_script("$(window).scrollTop(window.scrollMaxY / 2)");
    page.execute_script("$(window).trigger(\"scroll\")");
    wait_for(2)
  end

  def scroll_window_to_bottom
    page.execute_script("$(window).scrollTop(window.scrollMaxY)")
    page.execute_script("$(document).trigger(\"scroll\")")
    wait_for(2)
  end

  def click_scroll_to_top_button
    button = nil
    wait_a_while_for do
      button = page.find(:css, "a#scroll-top", :visible => true)
    end
    button.click()
    wait_for(2)
  end

  def page_should_be_at_top
    top = page.evaluate_script("$(window).scrollTop()")
    top.should == 0
  end
end

RSpec.configure do |config|
  config.include ScrollingIntegrationHelpers
end
