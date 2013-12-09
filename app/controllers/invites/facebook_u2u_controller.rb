module Invites
  class FacebookU2uController < ApplicationController
    include Controllers::InviteBar

    respond_to :json

    # XXX: should move to feed/invite_bar/requests_controller

    def create
      params[:request_id].present? or
        return render_jsend(fail: {message: "request_id param required"})
      params[:to].present? or
        return render_jsend(fail: {message: "to param required"})
      u2u_request = FacebookU2uRequest.create_invite_request!(current_user, params[:request_id], params[:to].split(','),
                                                              source: params[:source])
      # XXX: until we figure out why FB.ui explodes after calling our callback, just reload the page rather than
      # re-rendering the bar. the referring controller is responsible for removing the request id from the session.
      remember_invite_bar_request(u2u_request)
      render_jsend(success: {
#        bar: Invites::Facebook::U2uCreatedExhibit.new(u2u_request, current_user, view_context).render
        redirect: request.referer
      })
    end
  end
end
