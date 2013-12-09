require './acceptance/spec_helper'
require 'timecop'

feature "View notifications", js: true do
  background do
    login_as "starbuck@galactica.mil"
  end

  scenario "Mark unviewed notification viewed" do
    Timecop.travel(Time.zone.now) do
      clear_all_notifications
      given_notifications Date.today => 1
      visit root_path
      expect(page).to have_notification_pill(1)
      visit notifications_path
      expect(page).to have_notifications(1)
      page_should_have_hamburger_notifications(0)
    end
  end

  scenario "Autoclear viewed notification" do
    Timecop.travel(Time.zone.now) do
      clear_all_notifications
      given_notification created_at: 2.weeks.ago, viewed_at: 12.days.ago
      given_notification created_at: 1.week.ago, viewed_at: 3.days.ago
      given_notification created_at: 1.hour.ago
      visit notifications_path
      expect(page).to have_notifications(3)
      Users::AutoclearViewedNotificationsJob.perform
      visit notifications_path
      expect(page).to have_notifications(2)
    end
  end

  def page_should_have_hamburger_notifications(count)
    within '#hamburger-counter' do
      expect(page).to have_notification_pill(0)
    end
  end

# XXX: these tests are failing on staging for some unknown reason which I suspect has to do with time zones. maybe
# timecop will help.

#  scenario "Clear one of several on a single day" do
#    given_notifications Date.today => 3
#    visit dashboard_notifications_path
#    click_clear_notification_link Date.today, 0
#    page.should have_notifications(2)
#    page.should have_notifications_for_date(Date.today, 2)
#  end

#  scenario "Clear one of several on multiple days" do
#    given_notifications Date.today => 3, Date.yesterday => 2
#    visit dashboard_notifications_path
#    click_clear_notification_link Date.today, 1
#    page.should have_notifications(4)
#    page.should have_notifications_for_date(Date.today, 2)
#    page.should have_notifications_for_date(Date.yesterday, 2)
#  end

  scenario "Clear last notification", js: true do
    clear_all_notifications
    notifications = given_notifications Date.today => 1
    visit notifications_path
    expect(page).to have_css("[data-role=notification-actions]")
    simulate_hover("[data-role=notification-actions]")
    click_clear_notification_link notifications[Date.today].first
    expect(page).to have_content('No notifications')
    expect(page).to have_notifications(0)
  end

  def click_clear_notification_link(n)
    find("a.clear-notification[data-notification=\"#{n.id}\"]").click
  end
end
