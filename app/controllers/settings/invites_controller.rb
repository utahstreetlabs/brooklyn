class Settings::InvitesController < ApplicationController
  layout 'settings'

  def show
    @invites = Datagrid::ArrayDatagrid.new(InvitesSent.new(current_user), params)
  end
end
