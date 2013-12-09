class Settings::CreditsController < ApplicationController
  layout 'settings'

  def show
    @credits = current_user.credits.datagrid(params)
    @triggers = current_user.triggers_by_id
  end
end
