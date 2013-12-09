require 'spec_helper'

describe Facebook::NotificationPriceAlertJob do
  subject { Facebook::NotificationPriceAlertJob }

  let(:users) do
    1.upto(3).map do |i|
      user = FactoryGirl.create(:registered_user)
      user.update_column(:registered_at, i.hours.ago)
      user
    end
  end

  let(:profiles) do
    users.map do |user|
      stub_network_profile("#{user.name}-facebook", Network::Facebook.to_sym, name: user.name,
                           person_id: user.person.id, connected?: true)
    end
  end

  it "enqueues a post job for each connected profile" do
    Profile.stubs(:find_for_people_and_network).
      with([users.first.person_id, users.second.person_id], Network::Facebook).
      returns(profiles.slice(0, 2))
    profiles.second.stubs(:connected?).returns(false)
    Facebook::NotificationPriceAlertPostJob.expects(:enqueue).with(profiles.first.id)
    Facebook::NotificationPriceAlertPostJob.expects(:enqueue).with(profiles.second.id).never
    Facebook::NotificationPriceAlertPostJob.expects(:enqueue).with(profiles.third.id).never
    subject.work(2)
  end
end
