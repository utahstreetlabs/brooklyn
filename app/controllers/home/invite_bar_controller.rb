class Home::InviteBarController < ApplicationController
  include Controllers::InviteBar

  respond_to :json

  def destroy
    remember_invite_bar_closed
    render_jsend(:success)
  end
end
