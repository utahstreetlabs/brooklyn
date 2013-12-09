require 'ladon'

class GrantInviteeCredit < Ladon::Job
  @queue = :credits

  def self.work(invitee_id)
    with_error_handling("Granting invitee credit", user_id: invitee_id) do
      Credit.grant_if_eligible!(User.find(invitee_id), :invitee)
    end
  end
end
