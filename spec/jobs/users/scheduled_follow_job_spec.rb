require "spec_helper"

describe Users::ScheduledFollowJob do
  let(:follower) { FactoryGirl.create(:registered_user) }
  let(:followee) { FactoryGirl.create(:registered_user) }

  it 'creates a scheduled follow between the users' do
    Users::ScheduledFollowJob.perform(followee.id, follower.slug)
    expect(Follow.where(user_id: followee.id, follower_id: follower.id)).to be
  end
end
