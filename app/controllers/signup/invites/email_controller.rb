class Signup::Invites::EmailController < ApplicationController
  layout 'signup/invites'

  def index
  end

  def create
    @invite = EmailInvite.new(params[:invite])
    if @invite.valid?
      ::Invites::EmailContext.send_messages(current_user, @invite)
      redirect_to(signup_onboard_path)
    else
      render(:index)
    end
  end
end
