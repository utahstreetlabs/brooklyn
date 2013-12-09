class Info::ExtrasController < ApplicationController
  def show
    track_usage('extras_page view', username: current_user.slug)
  end
end
