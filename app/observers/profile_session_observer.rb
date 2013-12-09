class ProfileSessionObserver < ActiveModel::Observer
  observe :session

  def after_sign_in(session)
    user = session.user
    # a user who just registered will not have the profile yet (this sync will already be in process)
    if (user && user.registered? && !user.just_registered?)
      user.person.async_sync_connected_profiles
    end
  end
end
