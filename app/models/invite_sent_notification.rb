class InviteSentNotification < Notification
  attr_accessor :invitee_profile, :inviter, :invited

  def complete?
    ! (invitee_profile.nil? || inviter.nil?)
  end
end
