class Notifications::UnviewedController < ApplicationController
  respond_to :json

  def count
    render_jsend success: {count: current_user.unviewed_notification_count}
  end
end
