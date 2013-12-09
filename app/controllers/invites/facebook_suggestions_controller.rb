class Invites::FacebookSuggestionsController < ApplicationController
  respond_to :json

  def index
    suggestions = current_user.person.invite_suggestions(Brooklyn::Application.config.invite_modal.max_suggestions,
      name: params[:name])
    exhibit = Invites::Facebook::U2uSuggestionsExhibit.new(suggestions, current_user, view_context)
    render_jsend(success: {suggestions: exhibit.render})
  end
end
