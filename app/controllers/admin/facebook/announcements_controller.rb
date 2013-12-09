class Admin::Facebook::AnnouncementsController < AdminController
  include Controllers::AdminScoped

  respond_to :json, only: :create
  set_flash_scope 'admin.facebook.announcements'

  def index
  end

  def create
    ::Facebook::NotificationAnnounce.enqueue()
    render_jsend(success: {
      message: localized_flash_message(:sent),
      close: true
    })
  end
end
