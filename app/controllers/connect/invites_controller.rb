class Connect::InvitesController < ApplicationController
  include Controllers::FacebookProfileScoped
  layout 'connect'

  load_friend_boxes
  require_facebook_connection

  def index
    track_usage(:invites_view)
  end
end
