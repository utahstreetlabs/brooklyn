require 'rubicon/models/invite'
require 'rubicon/models/profile'
require 'rubicon/models/untargeted_invite'

# For now, a simple wrapper around Rubicon invites. Once we move invites into Brooklyn, this becomes a full-fledged
# AR model.
class Invite < SimpleDelegator
  def uuid
    id
  end

  def targeted?
    not untargeted?
  end

  def untargeted?
    __getobj__.is_a?(Rubicon::UntargetedInvite)
  end

  def inviter
    unless defined?(@inviter)
      person_id = if targeted?
        profile = Profile.find(__getobj__.inviter_id)
        profile && profile.person_id
      else
        __getobj__.person_id
      end
      @inviter = person_id && User.find_by_person_id(person_id)
    end
    @inviter
  end

  def inviter_id
    inviter && inviter.id
  end

  def accepters
    User.includes(:invite_acceptance).where(invite_acceptances: {invite_uuid: uuid})
  end

  def self.untargeted(attrs = {})
    Rubicon::UntargetedInvite.new(attrs)
  end

  def self.targeted(attrs = {})
    Rubicon::Invite.new(attrs)
  end

  def self.find_by_uuid(uuid)
    invite = Rubicon::UntargetedInvite.find(uuid) || Rubicon::Invite.find(uuid)
    invite && new(invite)
  end

  def self.find_by_person_id(id)
    invite = Rubicon::UntargetedInvite.find_for_person(id)
    invite && new(invite)
  end

  def self.find_from_u2us(u2us)
    u2us.each do |u2u|
      invite = find_by_uuid(u2u.invite_code)
      return [invite, u2u] if invite
    end
    nil
  end

  def self.find_inviters_of_profile_uuid(uuid)
    Rubicon::Invite.inviters(uuid)
  end

  def self.config
    Brooklyn::Application.config.invites
  end

  # The maximum number of acceptances of this invite that can be credited.
  def self.max_creditable_acceptances
    config.max_creditable_acceptances
  end
end
