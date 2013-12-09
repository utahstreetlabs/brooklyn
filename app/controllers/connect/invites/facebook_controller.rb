class Connect::Invites::FacebookController < ApplicationController
  include Controllers::FacebookProfileScoped

  layout 'connect'
  set_flash_scope 'connect.invites.facebook'
  respond_to :json, only: :search
  require_facebook_connection
  load_friend_boxes only: :search

  def search
    render_jsend(success: {results: @friend_boxes})
  end

  def create
    @invite = FacebookInvite.new(params[:invite])
    if @invite.valid?
      ::Invites::FacebookDirectShareContext.async_send_direct_shares(current_user, @invite)
      flash[:invited] = @invite.ids.size
    else
      set_flash_message(:alert, :invite_error)
    end
    redirect_to(connect_invites_path)
  end
end
