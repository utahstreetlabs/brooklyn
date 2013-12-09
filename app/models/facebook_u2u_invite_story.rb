class FacebookU2uInviteStory < LocalStory
  attr_reader :friend_profiles, :friend_count

  def initialize(friend_profiles, friend_count = nil, options = {})
    super(options)
    @friend_profiles = friend_profiles
    @friend_count = friend_count
  end

  def type
    :facebook_u2u_invite
  end
end
