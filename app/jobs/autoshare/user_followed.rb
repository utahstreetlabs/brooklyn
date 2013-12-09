require 'ladon'

class Autoshare::UserFollowed < Ladon::Job
  acts_as_unique_job

  @queue = :sharing

  def self.work(followee_id, followee_url, follower_id)
    with_error_handling("autoshare user followed", followee_id: followee_id, follower_id: follower_id) do
      followee = User.find(followee_id)
      follower = User.find(follower_id)
      follower.autoshare(:user_followed, followee, followee_url)
    end
  end
end
