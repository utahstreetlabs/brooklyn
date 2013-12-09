require 'context_base'

module Invites
  class EmailContext < ContextBase
    def self.send_messages(inviter, invite)
      logger.debug("Inviting via email from user #{inviter.id} to #{invite.addresses.join(', ')}")
      inviter.mark_inviter!
      invite.addresses.each do |recipient|
        send_email(:invite, inviter, recipient, invite.message)
        track_usage(:invite_sent, user: inviter, inviter: inviter.name, invitee: recipient, type: :email)
      end
    end
  end
end
