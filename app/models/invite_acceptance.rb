class InviteAcceptance < ActiveRecord::Base
  belongs_to :user
  belongs_to :facebook_u2u_invite

  attr_accessible :invite_uuid, :inviter_id

  def invite
    unless defined?(@invite)
      @invite = Invite.find_by_uuid(invite_uuid)
    end
    @invite
  end

  # XXX: when invites are brought into brooklyn, we'll join to the invites table for these queries rather than
  # storing these values in this table

  def self.find_credited_for_invite(uuid)
    where(invite_uuid: uuid, credited: true)
  end

  def self.count_credited_for_invite(uuid)
    find_credited_for_invite(uuid).count
  end

  def self.find_credited_for_inviter(inviter_id)
    where(inviter_id: inviter_id, credited: true)
  end

  def self.count_credited_for_inviter(inviter_id)
    find_credited_for_inviter(inviter_id).count
  end

  after_commit on: :create do
    InviteAcceptances::AfterCreationJob.enqueue(self.id)
  end
end
