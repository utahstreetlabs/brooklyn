class Settings::Seller::IdentityController < ApplicationController
  layout 'settings'
  set_flash_scope 'settings.seller.identity'

  before_filter do
    redirect_to(settings_seller_accounts_path) if current_user.balanced_merchant?
  end

  def show
    # using a region query param allows us simulate a "need more information" error from Balanced
    @identity = Balanced::PersonMerchantIdentity.new(born_on: nil, region: params[:region], attempt: 1)
  end

  def update
    @identity = Balanced::PersonMerchantIdentity.new(identity_params)
    if @identity.valid?
      begin
        current_user.create_merchant!(@identity)
        # no flash message by design
        return redirect_to(settings_seller_accounts_path)
      rescue Balanced::MoreInformationRequired => e
        logger.warn("Could not validate merchant identity #{@identity.to_merchant_params} for user #{current_user.id} on attempt #{@identity.attempt}: #{e.message}")
        @identity.attempt += 1
        if @identity.attempt == 2
          set_flash_message(:alert, :attempt2)
        elsif @identity.attempt == 3
          set_flash_message(:alert, :attempt3,
                            help_link: view_context.mail_to(Brooklyn::Application.config.email.to.help))
        else
          return render(:failure)
        end
      rescue Balanced::Error => e
        # something else went wrong. ask the user to try again or contact us.
        logger.warn("Error creating Balanced merchant account with identity #{@identity.to_merchant_params} for user #{current_user.id}: #{e.message}")
        set_flash_message(:alert, :error_updating,
                          help_link: view_context.mail_to(Brooklyn::Application.config.email.to.help))
      end
    end
    render(:show)
  end

  protected
    def identity_params
      params[:identity].slice(:name, :street_address, :postal_code, :phone_number, :'born_on(1i)', :'born_on(2i)',
                              :'born_on(3i)', :tax_id, :region, :attempt)
    end
end
