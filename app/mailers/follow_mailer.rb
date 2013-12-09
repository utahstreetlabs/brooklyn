class FollowMailer < MailerBase
  def follow(follow)
    @followee = follow.followee
    @follower = follow.follower
    @follower_listing_infos = @follower.representative_listing_infos(count: 4)
    campaign = 'userfollow'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    track_usage('email_follow send', follower: @follower.slug, followee: @followee.slug, type: follow.type_code) do
      setup_mail(:follow, headers: {to: @followee.email}, params: {follower: @follower.name})
    end
  end
end
