require 'invites/facebook_direct_share_context'
require 'ladon'

module Facebook
  class DirectShareInviteJob < Ladon::Job
    @queue = :facebook

    def self.work(inviter_id, invitee_id, params = {})
      with_error_handling("send direct share invite", inviter_id: inviter_id, invitee_id: invitee_id, params: params) do
        inviter = Person.find(inviter_id)
        Invites::FacebookDirectShareContext.send_direct_share(inviter, invitee_id, params)
      end
    end
  end
end
