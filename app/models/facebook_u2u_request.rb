# Represents a Facebook U2U app request aggregating a group of invitations to various FB users to join Copious. The
# individual invite requests, each directed to a different user, are represented by +FacebookU2uInvite+s.
#
# @see https://developers.facebook.com/docs/requests/
class FacebookU2uRequest < ActiveRecord::Base
  has_many :invites, class_name: 'FacebookU2uInvite', dependent: :destroy
  belongs_to :user
  attr_accessible :fb_request_id
  after_commit :mark_inviter!, :on => :create

  def invite_count
    invites.count
  end

  def amount_for_accepted_invites
    Credit.amount_for_accepted_invites(invite_count)
  end

  # Creates and returns a U2U invite request along with an invite for each invitee.
  #
  # @options option [String] :source the area of the app where the invite was generated (eg invite_modal)
  # @return [FacebookU2uRequest]
  def self.create_invite_request!(user, fb_request_id, fb_invitee_ids, options = {})
    logger.debug("Creating Facebook U2U request #{fb_request_id} to invitees #{fb_invitee_ids} with options #{options}")
    transaction do
      request = new(fb_request_id: fb_request_id)
      request.user = user
      request.save!
      fb_invitee_ids.each do |fb_user_id|
        attrs = {
          fb_user_id: fb_user_id,
          invite_code: user.untargeted_invite_code,
          source: options[:source]
        }
        request.invites.build(attrs).save!
      end
      request
    end
  end

  def mark_inviter!
    self.user.mark_inviter!
  end
end
