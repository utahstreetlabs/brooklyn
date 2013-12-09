# Allows the user to follow and unfollow the followers and followees of another user from that user's profile.
#
# Example: The current user (A) views the followers page for the profile user (B). He clicks the follow button for
# one of the followers (C) of B to follow C himself.
class Profiles::FolloweesController < ApplicationController
  include Controllers::ProfileScoped
  include Controllers::Jsendable

  attr_reader :followee

  respond_to :json
  load_profile_user
  before_filter :load_followee
  customize_action_event variables: [:profile_user]

  def update
    current_user.follow!(followee)
    respond_to_follow_unfollow(true)
  end

  def destroy
    current_user.unfollow!(followee)
    respond_to_follow_unfollow(false)
  end

protected
  def load_followee
    @followee = User.find_by_slug!(params[:id])
  end

  def respond_to_follow_unfollow(following)
    respond_to do |format|
      format.json do
        strip = UserStripCollection::UserStrip.new(followee, viewer_following: following)
        button = view_context.profile_user_strip_follow_button(strip, current_user, profile_user)
        data = {button: button, followersCount: followee.registered_followers.count, following: following}
        render_jsend(success: data)
      end
    end
  end
end
