module NotificationHelpers
  RSpec::Matchers.define :have_notification_pill do |count|
    match do |page|
      pill_count(page, (count > 0)) == count
    end
    def pill_count(page, visible)
      page.find('[data-role=notification-pill]', visible: visible).text.strip.to_i
    end
  end

  RSpec::Matchers.define :have_notifications do |count|
    match do |page|
      page.has_css?('.notification', count: count)
    end
    failure_message_for_should do |page|
      "expected #{count} notifications, not #{notification_count(page)}"
    end
  end

  RSpec::Matchers.define :have_notifications_for_date do |date, count|
    match do |page|
      page.within(".date[data-date=\"#{date.to_time.to_i}\"]") do
        notification_count(page) == count
      end
    end
    failure_message_for_should do |actual|
      "expected #{count} notifications for #{date}, not #{actual}"
    end
  end

  def notification_count(page)
    page.all('.notification').size
  end
end

RSpec.configure do |config|
  config.include NotificationHelpers
end
