class Listings::HotnessController < ApplicationController
  include Controllers::ListingScoped
  set_listing
  respond_to :json

  def create
    current_user.like(@listing)
    render_success
  end

  def destroy
    current_user.dislike(@listing)
    render_success
  end

  protected

    def render_success
      hot_or_not_suggestions = HotOrNotSuggestions.new(HotOrNotService.new(current_user))
      suggestions = Listings::HotOrNot::SuggestionsExhibit.new(hot_or_not_suggestions, current_user, view_context)
      render_jsend(success: {suggestions: suggestions.render, likes_count: current_user.likes_count})
    end
end
