require 'ladon'

module Facebook
  class DeleteU2uInviteRequestJob < Ladon::Job
    @queue = :facebook

    def self.work(u2u_id)
      with_error_handling("Deleting app request for Facebook U2U invite #{u2u_id}", facebook_u2u_invite_id: u2u_id) do
        u2u = FacebookU2uInvite.find(u2u_id)
        u2u.delete_app_request!
      end
    end
  end
end
