class Admin::Users::FollowEmailsController < ApplicationController
  set_flash_scope 'admin.users.follow_emails'
  load_and_authorize_resource :user, class: 'User'

  def create
    if current_user.following?(@user)
      Follows::AfterCreationJob.send_user_follow_email(current_user.follow_of(@user), notify_followee: true,
                                                       refollow: true)
      set_flash_message(:notice, :created)
    else
      set_flash_message(:alert, :error_creating)
    end
    redirect_to(admin_user_path(@user.id))
  end
end
