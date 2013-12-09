require 'context_base'
require 'facebook/direct_share_invite_job'

module Invites
  class FacebookDirectShareContext < ContextBase
    def self.eligible_profiles(inviter, options = {})
      limit = options.fetch(:limit, 150)
      renderer = options[:renderer] or raise ArgumentError.new(":renderer option required")
      invite_suggestions = inviter.person.invite_suggestions(limit, name: options[:name])
      invite_suggestions.inject('') do |m, p|
          m << renderer.render_to_string(partial: '/connect/invites/modules/facebook/friend_box.html',
                                         locals: {profile: p})
      end
    end

    def self.async_send_direct_shares(inviter, invite)
      invite.ids.each do |invitee_id|
        ::Facebook::DirectShareInviteJob.enqueue(inviter.person.id, invitee_id, message: invite.message,
                                                 picture: absolute_url(inviter.profile_photo_url,
                                                 root_url: url_helpers.root_url))
      end
    end

    def self.send_direct_share(inviter, invitee_id, params = {})
      uh = self.url_helpers
      url_generator = lambda {|i| uh.invite_url(i)}
      logger.debug("Inviting via direct share from person #{inviter.id} to Facebook profile #{invitee_id}")
      inviter.invite!(invitee_id, url_generator, params: params)
      inviter.user.mark_inviter!
      track_usage(:invite_sent, user: inviter.user, inviter: inviter.user.name, invitee: invitee_id, type: :facebook_direct_share)
    end
  end
end
