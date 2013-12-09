class IdentityObserver < ObserverBase
  def after_update_from_oauth(identity)
    begin
      Profile.find_or_create!(identity.person.id, identity.provider, identity.uid, reassign: true)
    rescue
      # profile sync will try to repair, even if the initial find_or_create! fails, so we keep calm and carry on
      logger.error("Failed to create profile for network #{identity.provider} and uid #{identity.uid} in" +
        " IdentityObserver")
    end
    sync_class = identity.sync_class || Profiles::SyncAll
    sync_class.enqueue(identity.person.id, identity.uid, identity.provider)
    Network.klass(identity.provider).update_preferences(identity.user, scope: identity.scope)
  end
end
