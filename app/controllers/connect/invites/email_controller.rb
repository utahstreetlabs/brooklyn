class Connect::Invites::EmailController < ApplicationController
  layout 'connect'
  set_flash_scope 'connect.invites.email'

  def create
    @invite = EmailInvite.new(params[:invite])
    if @invite.valid?
      ::Invites::EmailContext.send_messages(current_user, @invite)
      flash[:invited] = @invite.addresses.size
    else
      set_flash_message(:alert, :invite_error)
    end
    redirect_to(connect_invites_path)
  end
end
