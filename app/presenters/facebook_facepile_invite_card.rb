class FacebookFacepileInviteCard < FeedCard
  delegate :friend_profiles, :friend_count, to: :story
end
