class Settings::Seller::Accounts::PaypalController < ApplicationController
  layout 'settings'
  set_flash_scope 'settings.seller.accounts.paypal'

  before_filter do
    redirect_to(settings_seller_identity_path) unless current_user.balanced_merchant?
  end

  def edit
    @account = PaypalAccount.find(params[:id])
  end

  def update
    @account = PaypalAccount.find(params[:id])
    if @account.update_attributes(account_params)
      set_flash_message(:notice, :updated)
      redirect_to(settings_seller_accounts_path)
    else
      render(:edit)
    end
  end

  protected
    def account_params
      params[:account].slice(:email, :email_confirmation, :default)
    end
end
