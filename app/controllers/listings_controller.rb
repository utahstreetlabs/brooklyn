class ListingsController < ApplicationController
  include Controllers::Jsendable
  include Controllers::ListingScoped

  # perform access control before setting the listing
  ensure_login_or_guest only: [:new, :create]
  skip_requiring_login_only only: [:new, :create, :setup, :edit, :update, :draft, :complete, :show, :external, :share]
  require_login_or_guest only: [:new, :create, :setup, :edit, :update, :draft, :complete]
  require_admin only: [:sandbox]

  set_listing :only => [:show, :invoice, :sandbox], :includes => [:brand, :size, :category, :tags, {seller: :person},
                        {order: [:buyer_rating, :seller_rating]}, {features: :featurable}]
  set_listing :only => [:setup, :edit], :includes => [:tags]
  set_listing :only => [:draft, :complete, :activate, :update, :like, :unlike, :flag, :destroy, :change_shipping,
                        :share, :external]
  set_listing :only => [:ship, :deliver, :not_delivered, :finalize, :private, :public], :includes => [:order]

  require_seller :only => [:edit, :setup, :draft, :complete, :activate, :update, :ship, :destroy]
  # a listing can be seen by anybody if it's active or sold. it can only be seen by an admin or the seller in any
  # other state.
  require_seller :only => [:show], :unless => :listing_visible_to_non_seller?
  require_buyer :only => [:deliver, :not_delivered, :finalize, :change_shipping, :private, :public]
  require_state(:incomplete, :only => [:setup, :draft, :complete])
  require_transitionable(:cancel, :only => [:destroy])

  before_filter :load_sell_categories, :only => [:setup, :complete, :edit, :update]

  skip_enable_autologin
  enable_autologin only: [:show], :if => :listing_visible_to_non_seller?

  customize_action_event variables: [:listing], params: [:src]

  before_filter :only => [:edit, :setup] do
    params[:listing] = {
      :dimensions => @listing.dimension_values_id_map,
      :tags => @listing.tags.map{|t| t.name}.join(', ')
    }
  end

  respond_to :json, only: [:private, :public]

  def new
    # simply a GET-based entry point to create, useful for emails and other out-of-app contexts that can't embed forms
    # with CSRF protection
    create
  end

  def create
    if guest?
      @listing = guest_user.seller_listings.first
      # if there's an existing listing, we want to send the guest to the right point in the flow. if the listing is
      # incomplete, then we go to the setup page so he can complete it. if it's inactive, then we go to the listing
      # page so he can preview and publish it. if it's in any other state, then something's broken.
      if @listing
        if @listing.incomplete?
          return redirect_to(setup_listing_path(@listing))
        elsif @listing.inactive?
          return redirect_to(listing_path(@listing))
        else
          raise "Guest #{guest_user.id} has listing #{@listing.id} in unsupported state #{@listing.state}"
        end
      end
    end
    @listing = InternalListing.new_placeholder
    @listing.seller = guest?? guest_user : current_user
    @listing.save!
    redirect_to(setup_listing_path(@listing))
  end

  def setup
    @listing.title = nil if @listing.placeholder?
    track_usage(Events::CreateListingView.new(@listing))
  end

  def draft
    update_listing_attributes
    # skip validations since it's just an incomplete draft
    @listing.save!(validate: false)
    track_usage(Events::CreateDraftListing.new(@listing))
    redirect_to(setup_listing_path(@listing))
  end

  def complete
    update_listing_attributes
    @listing.reset_slug
    if @listing.complete
      track_usage(Events::CreateListing.new(@listing))
      redirect_to(listing_path(@listing))
    else
      set_flash_message(:alert, :not_saved, now: true)
      @listing.restore_slug
      render(:setup)
    end
  end

  def activate
    if @listing.activate
      request_display(:activation_cta)
      request_display(:listing_activation_trackers)
    else
      handle_state_transition_error(@listing, :activate)
    end
    redirect_to(listing_path(@listing))
  end

  def show
    if @listing.is_a?(ExternalListing)
      track_usage(Events::ViewExternalListing.new(@listing))
    else
      track_usage(Events::ListingView.new(@listing))
    end
    if params[:src] == 'featured'
      track_usage('featured-listing-clicked')
    elsif params[:src] == 'pa'
      # XXX: 060(b) - show flash when the user clicks through from a price alert notification. remove if/when we build
      # price alerts for real.
      set_flash_message(:alert, :price_alert_expired, now: true)
    end
    prepare_to_show_listing
  end

  def external
    track_usage(Events::RedirectExternalListing.new(@listing, clicker: current_user))
    redirect_to(@listing.source.url)
  end

  def invoice
    prepare_to_show_listing
    render 'invoice', :layout => 'printable'
  end

  def edit
    track_usage(Events::EditListingView.new(@listing, edited_at: Time.zone.now))
  end

  def update
    params[:listing][:dimensions] ||= {}
    update_listing_attributes
    if @listing.save
      set_flash_message(:notice, :updated)
      track_usage(Events::EditListing.new(@listing))
      redirect_to(listing_path(@listing))
    else
      set_flash_message(:alert, :not_saved, now: true)
      render(:edit)
    end
  end

  def like
    options = params[:shared].present?? {shared: params[:shared]} : {}
    like = current_user.like(@listing, options)
    respond_to do |format|
      format.json do
        render_jsend(success: Listings::LovedExhibit.new(@listing, like, current_user, view_context).render)
      end
      format.all { redirect_to(listing_path(@listing)) }
    end
  end

  def unlike
    current_user.unlike(@listing)
    respond_to do |format|
      format.json do
        render_jsend(success: Listings::UnlovedExhibit.new(@listing, current_user, view_context).render)
      end
      format.all { redirect_to(listing_path(@listing)) }
    end
  end

  def flag
    @listing.flag(current_user)
    track_usage(:flag_listing)
    respond_to do |format|
      msg = localized_flash_message(:flagged)
      format.json do
        exhibit = Listings::FlaggedExhibit.new(@listing, current_user, view_context, full_thanks: true)
        render_jsend(success: {refresh: exhibit.render})
      end
      format.all { redirect_to(listing_path(@listing), :notice => msg) }
    end
  end

  def ship
    order = @listing.order
    if order.can_ship?
      order.build_shipment(shipment_params) unless order.shipment
      order.shipment.attributes = shipment_params
      if order.ship
        set_flash_message(:notice, :shipped)
        redirect_to(listing_path(@listing))
      else
        logger.warn("Unable to ship order %s: shipment had errors %s" %
          [order.id, order.shipment.errors.full_messages.join("; ")])
        prepare_to_show_listing
        render(:show)
      end
    else
      set_flash_message(:alert, :already_shipped)
      redirect_to(listing_path(@listing))
    end
  end

  def deliver
    @listing.order.deliver! if @listing.order.can_deliver?
    redirect_to(listing_path(@listing))
  end

  def not_delivered
    @listing.order.report_non_delivery!
    set_flash_message(:notice, :not_delivered,
                      support_link: view_context.mail_to(Brooklyn::Application.config.email.to.help))
    redirect_to(listing_path(@listing))
  end

  def finalize
    @listing.order.complete_and_attempt_to_settle!
    set_flash_message(:notice, :completed)
    redirect_to(listing_path(@listing))
  end

  def private
    @listing.order.make_private
    render_jsend(:success)
  end

  def public
    @listing.order.make_public
    render_jsend(:success)
  end

  def destroy
    if @listing.cancel
      track_usage(Events::CancelListing.new(@listing, canceled_at: Time.zone.now))
      set_flash_message(:notice, :canceled)
      redirect_to(dashboard_path)
    else
      handle_state_transition_error(@listing, :cancel)
      logger.error("Could not cancel #{@listing.inspect}")
      redirect_to(listing_path(@listing))
    end
  end

  def change_shipping
    if @listing.order.shipping_address_changeable?
      @listing.order.copy_master_shipping_address!(params[:address_id])
      set_flash_message(:notice, :shipping_address_changed)
    else
      set_flash_message(:notice, :shipping_address_unchangable)
    end
    redirect_to(listing_path(@listing))
  end

  # Populates a dialog for sharing a listing to +params[:network]+. Redirects to a URL on the network's site after
  # recording tracking info.
  def share
    network = params[:network].to_sym
    return respond_not_found unless network.in?(Network.shareable)
    photo = params[:photo_id].present? ? ListingPhoto.find(params[:photo_id]) : @listing.photos.first
    target_url = ::Listings::IndirectShareContext.share_dialog_url(network, @listing, photo, view_context)
    @listing.incr_shares(current_user, network)
    track_usage("share_listing_#{network}".to_sym)
    redirect_to(target_url)
  end

  def sandbox
    prepare_to_show_listing
  end

protected

  def load_sell_categories
    @sell_categories = Category.order_by_name
  end

  def prepare_to_show_listing
    @photos = @listing.photos.all
    @likes_summary = @listing.likes_summary
    @feed = ListingFeed.new(@listing)
    @like = current_user.like_for(@listing) if current_user
    @listing.incr_views if @listing.active?
  end

  def listing_visible_to_non_seller?
    admin? || (@listing && (@listing.active? || @listing.sold?))
  end

  def listing_unpublished?
    @listing && (@listing.incomplete? || @listing.inactive?)
  end

  def update_listing_attributes
    @listing.add_to_collection_slugs = params[:collection_slugs]
    @listing.attributes = (params[:listing] || {}).slice(:category_id, :title, :description, :dimensions, :size_name,
      :brand_name, :tags, :price, :shipping, :shipping_option_code, :handling_duration,
      :seller_pays_marketplace_fee, :free_shipping, :original_price, # XXX back compat - rm free shipping when prepaid ships
      :add_to_collection_slugs)
    flash[:warning] = @listing.warnings.messages.values.flatten.join(', ') if @listing.warnings.any?
  end

  def shipment_params
    params[:shipment].slice(:carrier_name, :tracking_number)
  end
end
