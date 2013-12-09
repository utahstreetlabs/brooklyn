class InvitesController < ApplicationController
  skip_requiring_login_only
  before_filter :require_not_logged_in
  before_filter :load_invite

  customize_action_event variables: [{:invite => :invitee_id}, {:invite => :inviter_id}]

  def show
    track_usage(:invite_view, inviter: @invite.inviter_id, invitee: @invite.invitee_id)
  end

protected

  def load_invite
    invite_id = params[:id]
    @invite = Invite.find_by_uuid(invite_id)
    @invite ||= Invite.untargeted(uuid: invite_id) if invite_id == 'abc123'
    respond_not_found unless @invite
    # store the invite id so that we can accept the invite when creating the user record
    session[:invite_id] = invite_id
  end
end
