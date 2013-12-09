class Dashboard::Invites::SuggestionsController < ApplicationController
  include Controllers::DashboardScoped
  include Controllers::InviteYourFriends

  respond_to :json, only: [:destroy]

  skip_action_event only: [:index, :destroy]

  def index
    count = (params[:count] || 1).to_i
    index = (params[:index] || -1).to_i
    @suggestions = current_user.person.invite_suggestions(count, blacklist: params[:blacklist])
    if @suggestions && @suggestions.any?
      fire_event(:invite_display_suggestion, user: current_user, invitee_ids: @suggestions.map(&:id),
        network: @suggestions[0].network)
    end
    respond_to do |format|
      format.json do
        suggestions = []
        if index == 0
          @pileon_suggestion = find_pileon(@suggestions)
          if @pileon_suggestion
            suggestions = [{ui: render_to_string(partial: '/shared/invite_friend_pileon.html',
                                                 locals: {inviter: inviter_profiles(@pileon_suggestion).first, invitee: @pileon_suggestion}, invite_suggestion_class: "rep-action"),
                             id: @pileon_suggestion.id}]
            @suggestions.delete(@pileon_suggestion)
          end
        end
        suggestions += @suggestions.map do |s|
          {ui: render_to_string(partial: '/shared/invite_friend.html',
                                locals: {profile: s, invite_suggestion_class: "rep-action"}),
            id: s.id}
        end
        render_jsend(success: {results: suggestions})
      end
      format.html do
        render layout: !request.xhr?
      end
    end
  end

  def destroy
    profile = Profile.find(params[:id])
    if profile
      fire_event(:invite_remove_suggestion, user: current_user, invitee_id: profile.id, network: profile.network)
      current_user.person.blacklist_invite_suggestion(profile.id)
      render_jsend(:success)
    else
      render_jsend(error: 'Not Found')
    end
  end
end
