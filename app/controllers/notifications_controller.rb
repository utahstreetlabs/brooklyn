class NotificationsController < ApplicationController
  include Controllers::InfinitelyScrollable

  def index
    @notifications = UserNotifications.new(current_user, params.slice(:per, :page, :mark_viewed))
    @page_manager = @notifications.page_manager
    current_user.mark_all_notifications_viewed
    respond_to do |format|
      format.html do
        track_usage('notifications view')
      end
      format.json do
        results = { cards: view_context.notification_rows(@notifications) }
        results[:more] = next_page_path unless last_page?
        render_jsend(success: results)
      end
    end
  end

  def destroy
    current_user.clear_notification(params[:id])
    render_jsend(success: {notificationId: params[:id]})
  end
end
