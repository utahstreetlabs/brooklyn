class EmailAccountsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:create]
  respond_to :json, :only => [:contacts, :invite_contacts]

  def new
  end

  def create
    begin
      account = EmailAccount.get_or_create_with_user_and_token(current_user, params[:token])
      account.async_sync_contacts!
      redirect_to(email_account_path(account))
    rescue Exception => e
      logger.error("Failed to connect to Janrain to import contacts for user_id #{current_user.id}")
      notify_airbrake(e)
      set_flash_message(:alert, :janrain_error)
      redirect_to(root_path)
    end
  end

  def show
    @account = EmailAccount.find(params[:id])
    @contacts_path = email_account_contacts_path(@account)
  end
end
