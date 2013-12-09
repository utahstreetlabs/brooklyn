require 'ladon'

class GrantInviterCredits < Ladon::Job
  @queue = :credits

  def self.work(invitee_id)
    with_error_handling("Granting inviter credit", invitee_id: invitee_id) do
      invitee = User.find(invitee_id)
      if inviter = invitee.accepted_inviter
        logger.info("Granting credit to user #{inviter.id} for inviting user #{invitee.id} if eligible")
        Credit.grant_if_eligible!(inviter, :inviter, invitee_id: invitee.id)
      end
    end
  end
end
