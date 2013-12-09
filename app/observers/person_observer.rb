class PersonObserver < ObserverBase
  def after_profile_update(person, network, options = {})
    if person.user.present?
      Profile.async_sync(person.id, network, options)
      update_network_preferences(person, network, options)
    end
  end

  def self.after_invite_sent(inviter_person, invitee_profile)
    track_usage(:invite_sent, user: inviter_person.user, inviter: inviter_person.id, invitee_profile_id: invitee_profile.id, network: invitee_profile.network)
    fire_event(:invite_sent, inviter: inviter_person.id, invitee_profile_id: invitee_profile.id, network: invitee_profile.network)
    notify_invitee_followers_invite_sent(inviter_person.user, invitee_profile)
  end

  # For each registered copious follower of the invitee in the same network, post a copious activity and notification
  # encouraging the copious user to send a "pile on" invite
  def self.notify_invitee_followers_invite_sent(inviter, invitee_profile)
    # Find all profiles that the invitee follows
    person_ids = invitee_profile.following.keep_if {|p| p.connected?}.map(&:person_id)
    interested_users = Person.where(id: person_ids).where('id != ?', inviter.person_id).includes(:user).map(&:user)
    interested_users.each do |user|
      inject_notification(:InviteSentPileOn, user.id, inviter_id: inviter.id, invitee_profile_id: invitee_profile.id)
    end
  end

  def update_network_preferences(person, network, options = {})
    Network.klass(network).update_preferences(person.user, options)
  end
end
