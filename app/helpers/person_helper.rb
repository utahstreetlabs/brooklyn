require 'network_helper'
require 'users_helper'

module PersonHelper
  include NetworkHelper
  include UsersHelper

  # get a copious public profile if it's a user, otherwise, point to a facebook public profile
  def link_to_person_profile(person, options = {})
    if person.registered?
      link_to_user_profile person.user, options
    else
      facebook_profile = person.for_network(:facebook)
      link_to_network_profile(facebook_profile, options) if facebook_profile
    end
  end

  def person_avatar_small(person, options = {})
    if person.registered?
      user_avatar_xsmall(person.user, options)
    else
      facebook_profile = person.for_network(:facebook)
      link_to_profile_avatar(facebook_profile, options) if facebook_profile
    end
  end
end
