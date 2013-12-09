class Admin::Facebook::PriceAlertsController < AdminController
  include Controllers::AdminScoped

  set_flash_scope 'admin.facebook.price_alerts'

  def index
    @individual = prepare_individual_message
    @mass = prepare_mass_message
  end

  def create
    alerter = PriceAlerter.new
    message = alerter.new_message(message_params)
    if message.valid?
      begin
        alerter.send_message!(message)
        if message.respond_to?(:user)
          set_flash_message(:notice, :sent_individual, user: CGI::escapeHTML(message.user.formatted_email))
        else
          set_flash_message(:notice, :sent_mass, count: view_context.number_with_delimiter(message.count))
        end
      rescue Network::NotConnected
        set_flash_message(:alert, :not_connected, user: CGI::escapeHTML(message.user.formatted_email))
      end
      redirect_to(admin_facebook_price_alerts_path)
    else
      if message.respond_to?(:user)
        @individual = message
        @mass = prepare_mass_message
      else
        @individual = prepare_individual_message
        @mass = message
      end
      render(:index)
    end
  end

  private
    def prepare_individual_message
      PriceAlerter::IndividualMessage.new
    end

    def prepare_mass_message
      PriceAlerter::MassMessage.new(count: 10000)
    end

    def message_params
      params[:message].slice(:query, :slug, :count)
    end

    def create_message(attributes = {})
      if attributes.key?(:slug)
        IndividualPriceAlertMessage.new(attributes)
      else
        MassPriceAlertMessage.new(attributes)
      end
    end
end
