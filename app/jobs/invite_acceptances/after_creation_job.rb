module InviteAcceptances
  class AfterCreationJob < Ladon::Job
    include Stats::Trackable

    @queue = :users

    def self.work(id)
      with_error_handling("After creation of invite acceptance #{id}") do
        invite_acceptance = InviteAcceptance.find(id)
        update_mixpanel(invite_acceptance)
      end
    end

    def self.update_mixpanel(invite_acceptance)
      recipient = invite_acceptance.user
      # slightly different tracking for u2u invites than other types
      u2u = invite_acceptance.facebook_u2u_invite
      if u2u
        sender = u2u.request.user
        track_usage(:invite_accepted, user: recipient, source: u2u.source, share_channel: 'facebook_request',
                    sender: sender.slug, recipient: u2u.fb_user_id)
      else
        sender = recipient.accepted_inviter
        track_usage(:invite_accepted, user: recipient, inviter: sender.slug, invitee: recipient.slug)
      end
     sender.mixpanel_increment!(:invites_accepted)
    end
  end
end
