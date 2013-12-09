class FollowSuggestionsController < ApplicationController
  respond_to :json, only: :destroy

  def index
    count = params[:count] || 1
    @suggested_users = current_user.follow_suggestions(count.to_i, blacklist: params[:blacklist])
    @connections = SocialConnection.all(current_user, @suggested_users)
    respond_to do |format|
      format.json do
        suggestions = @suggested_users.map do |user|
          {ui: view_context.follow_suggestion(user, @connections[user.person_id]), id: user.id}
        end
        render_jsend(success: {results: suggestions})
      end
      format.html do
        render layout: !request.xhr?
      end
    end
  end

  def destroy
    current_user.blacklist_follow_suggestion(params[:id])
    render_jsend(:success)
  end
end
