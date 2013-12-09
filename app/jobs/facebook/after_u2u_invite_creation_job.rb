require 'ladon'
require 'brooklyn/sprayer'

module Facebook
  class AfterU2uInviteCreationJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :facebook

    def self.work(id)
      with_error_handling("After creation of Facebook U2U invite #{id}", facebook_u2u_invite_id: id) do
        u2u = FacebookU2uInvite.find(id)
        update_mixpanel(u2u)
      end
    end

    def self.update_mixpanel(u2u)
      sender = u2u.request.user
      track_usage(:invite_sent, user: sender, source: u2u.source, share_channel: 'facebook_request',
                  sender: sender.slug, recipient: u2u.fb_user_id)
    end
  end
end
