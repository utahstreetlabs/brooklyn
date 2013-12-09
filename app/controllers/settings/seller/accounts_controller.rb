class Settings::Seller::AccountsController < ApplicationController
  layout 'settings'
  set_flash_scope 'settings.seller.accounts'

  before_filter do
    redirect_to(settings_seller_identity_path) unless current_user.balanced_merchant?
  end

  def index
    return redirect_to(new_settings_seller_account_path) if current_user.deposit_accounts.empty?
    set_accounts
    set_default_account_if_necessary
    set_default_account_type
    set_funds_waiting
  end

  def new
    set_funds_waiting
    set_default_account_if_necessary
    set_default_account_type
  end

  def create
    params[:account_type] = params[:account_type].to_sym
    @account = DepositAccount.factory(params[:account_type], account_params)
    @account.user_id = current_user.id
    is_first_deposit_account = current_user.deposit_accounts.empty?
    begin
      if @account.save
        if is_first_deposit_account
          set_flash_message(:notice, :payout_account_created)
        else
          set_flash_message(:notice, :deposit_account_created)
        end
        return redirect_to(settings_seller_accounts_path)
      end
    rescue DepositAccount::UnidentifiedBank
      set_flash_message(:alert, :unidentified_bank,
                        help_link: view_context.mail_to(Brooklyn::Application.config.email.to.help))
    end
    case params[:account_type]
    when DepositAccount::BANK then @bank_account = @account
    when DepositAccount::PAYPAL then @paypal_account = @account
    end
    set_accounts
    set_default_account_if_necessary
    set_funds_waiting
    render(is_first_deposit_account ? :new : :index)
  end

  def default
    @account = DepositAccount.find(params[:account_id])
    @account.update_attributes!(default: true)
    set_flash_message(:notice, :defaulted)
    redirect_to(settings_seller_accounts_path)
  end

  def destroy
    @account = DepositAccount.find(params[:id])
    @account.destroy
    set_flash_message(:notice, :destroyed)
    redirect_to(settings_seller_accounts_path)
  end

  protected
    def set_accounts
      @accounts = current_user.deposit_accounts
    end

    def set_default_account_if_necessary
      unless @bank_account
        @bank_account = DepositAccount.factory(DepositAccount::BANK)
        @bank_account.default = true if current_user.deposit_accounts.empty?
      end
      unless @paypal_account
        @paypal_account = DepositAccount.factory(DepositAccount::PAYPAL)
        @paypal_account.default = true if current_user.deposit_accounts.empty?
      end
    end

    def set_default_account_type
      params[:account_type] = DepositAccount::BANK
    end

    def set_funds_waiting
      @funds_waiting = current_user.proceeds_awaiting_settlement
    end

    def account_params
      params[:account].slice(:name, :number, :routing_number, :email, :email_confirmation, :default)
    end
end
