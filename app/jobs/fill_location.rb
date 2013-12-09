require "resque"
require 'ladon'

# Attempt to fill in User's location from an external network
class FillLocation < Ladon::Job
  @queue = :facebook

  def self.work(user_id)
    user = User.find(user_id)
    unless user.location
      # only facebook is supported for now
      profile = user.person.for_network(:facebook)
      if profile && profile.facebook_location
        user.update_attribute(:location, profile.facebook_location.name)
      end
    end
  end
end
