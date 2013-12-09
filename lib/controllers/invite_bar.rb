module Controllers
  # A concern for controllers that manage the invite bar.
  #
  # Because sending invite requests from the invite bar and closing the invite bar require state to be saved across
  # request boundaries, we use the session to store this state.
  module InviteBar
    extend ActiveSupport::Concern

    included do
      helper_method :invite_bar_request, :invite_bar_closed?
    end

    # Remembers the U2U request sent from the invite bar in the session so that subsequent loads of pages containing
    # the invite bar can identify the U2U request and thus know to render the invite bar in the "after" state.
    def remember_invite_bar_request(u2u_request)
      session[:ibri] = u2u_request.id
    end

    # Loads the U2U request previously remembered in the session, if any, and removes it from the session.
    def load_and_forget_invite_bar_request
      request_id = session.delete(:ibri) || session.delete(:u2u_request_id) # legacy session name
      # use find_by_id so that it returns nil if the request isn't found. this could happen if the session is stale
      # somehow.
      @invite_bar_request = FacebookU2uRequest.find_by_id(request_id) if request_id
    end

    # Returns the previously loaded U2U request, if any.
    def invite_bar_request
      @invite_bar_request
    end

    # Remembers in the session the fact that the user indicated the invite bar should be closed.
    def remember_invite_bar_closed
      session[:ibc] = true
    end

    # Returns whether or not the user ever indicated that the invite bar should be closed. Does not forget this fact
    # since we want the invite bar to be closed for the remainder of the session.
    def invite_bar_closed?
      !!session[:ibc]
    end
  end
end
