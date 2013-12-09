class InviteeInviteCappedTopMessage < TopMessage
  include ApplicationHelper
  include ActionView::Helpers::NumberHelper

  def initialize(invitee, inviter)
    params = {
      inviter_cap: inviter.credited_invite_acceptance_cap,
      total_earnable: smart_number_to_currency(invitee.total_amount_earnable_for_accepted_invites),
      links: {invite: :connect_invites_path}
    }
    super(:invitee_invite_capped, params)
  end
end
