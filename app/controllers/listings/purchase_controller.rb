class Listings::PurchaseController < ApplicationController
  include Controllers::ListingScoped

  customize_action_event variables: [:listing]
  layout 'listings/purchase'
  respond_to :json, only: [:credit]

  set_listing only: [:show, :sell, :destroy]
  set_listing except: [:show, :sell, :destroy], includes: [:photos, :seller, {order: :buyer}]
  require_listing except: :sell, state: :active, flash: :no_longer_active
  require_listing only: :sell, state: [:active, :sold], flash: :no_longer_active
  require_not_seller redirect: :listing
  require_no_order only: :show, redirect: :listing
  require_order status: [:pending], only: [:shipping, :create_shipping_address, :credit], redirect: :listing
  require_order status: [:pending, :confirmed], only: [:payment, :sell], redirect: :listing, flash: :order
  require_order status: [:pending], only: :destroy, redirect: :listing
  require_buyer except: :show, redirect: :listing

  # use "show" because we need to redirect to the beginning of the purchase path
  # after logging in an anonymous user who clicked "buy now"
  def show
    @order = @listing.initiate_order(current_user)
    if @order.persisted?
      track_usage(:initiate_order)
      redirect_to(shipping_listing_purchase_path(@listing))
    else
      set_flash_message(:notice, :create_failed)
      redirect_to(listing_path(@listing))
    end
  end

  def shipping
    @ship_to = ShipTo.create(@listing.order, current_user.sorted_shipping_addresses.all)
    @address = PostalAddress.new_shipping_address
  end

  # user created a shipping address, should move on to the payment page
  def create_shipping_address
    @address = current_user.shipping_addresses.build(params[:postal_address])
    if @address.save
      set_flash_message(:notice, :shipping_address_created)
      bill_to_shipping = params[:postal_address].fetch(:shipping_address, {}).fetch(:bill_to_shipping, false)
      update_pending!(@listing.order, @address.id, bill_to_shipping: bill_to_shipping)
      # use a secure redirect to ensure that people see the browser's trust indicator on the payment page
      redirect_to(payment_listing_purchase_url(@listing, secure: true))
    else
      @ship_to = ShipTo.create(@listing.order, current_user.sorted_shipping_addresses.all)
      render(:shipping)
    end
  end

  def credit
    order = @listing.order
    begin
      order.apply_credit_amount!(params[:credit_amount].to_d)
      applied = order.credit_amount.abs
      balance = current_user.credit_balance(listing: @listing)
      applicable = order.applicable_credit(balance)
      total = order.total_price
      data = {
        message: localized_flash_message(applied > 0 ? :credit_applied : :credit_removed),
        applied: view_context.number_to_unitless_currency(applied),
        balance: view_context.number_to_unitless_currency(balance),
        applicable: view_context.number_to_unitless_currency(applicable),
        total: view_context.number_to_unitless_currency(total)
      }
      render_jsend(success: data)
    rescue Credit::MinimumRealChargeRequired => e
      logger.info("failing to apply credit because minimum real charge isn't met: #{params[:credit_amount]} on order #{order.id}", )
      render_jsend(fail: {message: localized_flash_message(:minimum_charge_required,
        amount: view_context.number_to_currency(Credit.minimum_real_charge))})
    rescue Credit::NotEnoughCreditAvailable => e
      logger.info("failing to apply credit because not enough credit is available: #{params[:credit_amount]} on order #{order.id}", )
      render_jsend(fail: {message: localized_flash_message(:not_enough_credit)})
    end
  end

  # user selected an existing shipping address, should move on to the payment page
  def ship_to
    ship_to_attrs = params[:ship_to] || {}
    ship_to_attrs.merge!(master_addresses: current_user.sorted_shipping_addresses.all)
    @ship_to = ShipTo.new(ship_to_attrs)
    if @ship_to.valid?
      begin
        update_pending!(@listing.order, @ship_to.address_id, bill_to_shipping: @ship_to.bill_to_shipping)
        # use a secure redirect to ensure that people see the browser's trust indicator on the payment page
        redirect_to(payment_listing_purchase_url(@listing, secure: true))
      rescue StateMachine::InvalidTransition => e
        if @listing.order.errors[:payment]
          set_flash_message(:alert, :ship_to_failed)
          redirect_to(shipping_listing_purchase_path(@listing))
        else
          # Unknown errors are simply reraised and handled by the global exception handler.
          raise e
        end
      end
    else
      # this should never happen since the address radio buttons should always have a selection, though it could if a
      # hacked form is submitted (or a browser is broken)
      flash[:alert] = @ship_to.errors.full_messages.join("\n")
      @address = PostalAddress.new_shipping_address
      render(:shipping)
    end
  end

  def payment
    return redirect_to(shipping_listing_purchase_path(@listing)) unless @listing.order.shipping_address
    @purchase = Purchase.new(expires_on: Date.current)
    @purchase.bill_to_shipping_address(@listing.order.shipping_address) if @listing.order.bill_to_shipping
  end

  # user submitted payment details; should confirm order and move on to listing page
  def sell
    return redirect_to(listing_path(@listing)) unless @listing.order.can_confirm?
    @purchase = Purchase.new(purchase_params)
    if @purchase.valid?
      @listing.order.purchase = @purchase
      begin
        @listing.order.confirm!
        request_display(:listing_purchase_trackers)
        set_flash_message(:notice, :created)
        track_usage(Events::Buy.new(@listing.order))
        return redirect_to(listing_path(@listing))
      rescue Purchase::CardNotValidated
        set_flash_message(:alert, :card_not_validated)
        # don't clear the credit card details since they may be mostly right and just need a small fix
#        @purchase.errors.add(:card_number, :doublecheck)
#        @purchase.errors.add(:expires_on, :doublecheck)
#        @purchase.errors.add(:security_code, :doublecheck)
      rescue Purchase::CardRejected
        set_flash_message(:alert, :payment_rejected)
        # ditto
#        @purchase.errors.add(:card_number, :doublecheck)
#        @purchase.errors.add(:expires_on, :doublecheck)
#        @purchase.errors.add(:security_code, :doublecheck)
      rescue Orders::PaymentDeclined
        set_flash_message(:alert, :payment_declined)
        # clear the credit card details as the card can't even be tokenized
        @purchase.card_number = nil
        @purchase.expires_on = nil
        @purchase.security_code = nil
      end
    end
    render(:payment)
  end

  def destroy
    begin
      @listing.order.cancel!
      if params[:reserved_time_expired]
        set_flash_message(:notice, :reserved_time_expired)
      else
        set_flash_message(:notice, :canceled)
      end
    rescue Exception => e
      logger.error("Could not cancel order #{@listing.order.inspect} for listing #{@listing.id}", e)
      handle_state_transition_error(@listing, :cancel_order)
    end
    redirect_to(listing_path(@listing))
  end

protected

  def update_pending!(order, address_id, options = {})
    order.copy_master_shipping_address!(address_id)
    order.bill_to_shipping = options.fetch(:bill_to_shipping, order.bill_to_shipping)
    order.save!
  end

  def purchase_params
    params[:purchase].slice(:cardholder_name, :card_number, :'expires_on(1i)', :'expires_on(2i)', :'expires_on(3i)',
                            :security_code, :line1, :line2, :city, :state, :zip, :phone, :bill_to_shipping)
  end
end
