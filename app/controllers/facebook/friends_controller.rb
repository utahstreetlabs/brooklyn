class Facebook::FriendsController < ApplicationController
  include Controllers::FacebookProfileScoped

  skip_requiring_login_only
  set_facebook_profile

  respond_to :json

  def registered
    friends = User.network_followers(@fb_profile, limit: params[:limit], registered_only: true).map do |(user, profile)|
      {id: profile.uid, name: profile.name, slug: user.slug}
    end
    # XXX: since we don't support sync state in rubicon yet, just pretend the sync is always complete
    render_jsend(success: {friends: friends, state: :complete})
  rescue Exception => e
    logger.error("Error listing friends for Facebook profile #{params[:fbid]}: #{e}")
    render_jsend(error: e.message)
  end
end
