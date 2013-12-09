require 'spec_helper.rb'

describe Users::AutoclearViewedNotificationsJob do
  it "clears viewed notifications" do
    Timecop.freeze do
      User.expects(:clear_viewed_notifications).with(before: User.notifications_autoclear_viewed_period.ago)
      Users::AutoclearViewedNotificationsJob.perform
    end
  end
end
