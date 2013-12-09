class Admin::Users::HotOrNotController < ApplicationController
  respond_to :json
  set_flash_scope 'admin.users.hot_or_not'
  load_and_authorize_resource :user, class: 'User'

  def index
    render_jsend(success: {modal: render_suggestions(@user)})
  end

  protected
    def render_suggestions(user)
      suggestions = user.hot_or_not_suggestions
      render_to_string(partial: '/admin/users/hot_or_not/show_modal.html',
                       locals: {suggestions: suggestions})
    end
end
