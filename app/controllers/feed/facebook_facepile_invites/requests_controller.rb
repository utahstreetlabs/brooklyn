class Feed::FacebookFacepileInvites::RequestsController < ApplicationController
  respond_to :json

  def create
    params[:request_id].present? or
      return render_jsend(fail: {message: "request_id param required"})
    params[:to].present? or
      return render_jsend(fail: {message: "to param required"})
    u2u_request = FacebookU2uRequest.create_invite_request!(current_user, params[:request_id], params[:to].split(','),
                                                            source: params[:source])
    render_jsend(success: {
      creditAmount: view_context.smart_number_to_currency(u2u_request.amount_for_accepted_invites),
    })
  end
end
