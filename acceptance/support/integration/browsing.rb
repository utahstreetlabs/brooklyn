module BrowsingHelpers
  def current_path
    URI.parse(current_url).path
  end

  def filter_by_tag(tag)
    within "#sidebar .tags" do
      click_link tag
    end
  end

  def remove_filter(name)
    within(:xpath, "//span[@class='tag-interaction' and contains(text(), '#{name}')]") do
      click_link("x")
    end
  end
end

module PageSections
  def window_title
    find "head > title"
  end

  def page_title
    find '#listing-title'
  end

  def your_navigation
    find "#your-navigation"
  end

  def tag_filters
    find "#sidebar .tags"
  end

  def flash_notice
    find "[data-role=flash-notice]"
  end

  def flash_alert
    find "[data-role=flash-alert]"
  end

  def flash_error
    find "[data-role=flash-error]"
  end
end

RSpec.configure do |config|
  config.include BrowsingHelpers
  config.include PageSections
end
