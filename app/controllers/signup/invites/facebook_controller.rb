class Signup::Invites::FacebookController < ApplicationController
  include Controllers::FacebookProfileScoped

  respond_to :json, only: :search
  require_facebook_connection
  layout 'signup/invites'

  def index
  end

  def search
    results = ::Invites::FacebookDirectShareContext.eligible_profiles(current_user, renderer: self, name: params[:name])
    render_jsend(success: {results: results})
  end

  def create
    @invite = FacebookInvite.new(params[:invite])
    if @invite.valid?
      ::Invites::FacebookDirectShareContext.async_send_direct_shares(current_user, @invite)
      redirect_to(signup_onboard_path)
    else
      render(:index)
    end
  end
end
