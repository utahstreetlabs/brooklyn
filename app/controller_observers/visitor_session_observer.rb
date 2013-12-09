class VisitorSessionObserver < ControllerObserverBase
  observe :session

  delegate :visitor_identity, :set_visitor_id_cookie, to: :controller

  # ensure that we have persisted the visitor_identity cookie on the user object
  # if, however, it has already been persisted but the user has cleared a cookie or otherwise lost the permanent cookie
  # we force it back to the old one once they log in for longer term consistency
  def after_sign_in(session)
    user = session.user
    if user
      if user.visitor_id.present?
        set_visitor_id_cookie(user.visitor_id)
      else
        # this shouldn't happen, but better to warn and heal the system if it does
        Rails.logger.warn("Could not find visitor id for user #{user.id}, re-setting it")
        user.visitor_id = visitor_identity
        unless user.save(validate: false)
          Rails.logger.error("Failed to update visitor_id for user #{user.id}")
        end
      end
    end
  end
end
