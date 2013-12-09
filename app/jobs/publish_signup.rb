require 'brooklyn/sprayer'
require 'ladon'

class PublishSignup < Ladon::Job
  include Brooklyn::Sprayer
  include Brooklyn::Urls

  acts_as_unique_job

  @queue = :network

  def self.work(user_id)
    logger.debug("Posting signup to networks for user=>#{user_id}")
    with_error_handling("Posting signup actions", user_id: user_id) do
      user = User.find(user_id)
      user.person.network_profiles.each do |network, profile|
        profile = Array.wrap(profile).first
        if profile.feed_postable?
          message_params = {firstname: user.firstname, link: url_helpers.signup_url,
            picture: absolute_url(user.profile_photo_url, root_url: url_helpers.root_url)}
          profile.post_to_feed(Network.klass(network).message_options!(:signup, message_params))
        end
      end
    end
  end
end
