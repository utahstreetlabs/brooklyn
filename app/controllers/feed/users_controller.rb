class Feed::UsersController < ApplicationController
  respond_to :json

  before_filter :load_user

  def follow
    current_user.follow!(@user, source: 'feed')
    render_jsend(success: {
      follow: Feed::UserFollowedExhibit.new(@user, current_user, view_context).render,
      followers: @user.followers.count
    })
  end

  def unfollow
    current_user.unfollow!(@user, source: 'feed')
    render_jsend(success: {
      # UserFollowed works for both follow and unfollow states
      follow: Feed::UserFollowedExhibit.new(@user, current_user, view_context).render,
      followers: @user.followers.count
    })
  end

  protected
    def load_user
      @user = User.find_by_slug!(params[:user_id])
    end
end
