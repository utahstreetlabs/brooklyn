class Dashboard::Invites::ProfilesController < ApplicationController
  include Controllers::FeedPostable
  respond_to :json, only: :update

  def update
    with_feed_post_error_handling(params[:id]) do
      controller = self
      current_user.person.invite!(params[:id], lambda {|i| controller.invite_url(i)})
      render_jsend(success: {})
    end
  end
end
