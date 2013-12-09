class DashboardController < ApplicationController
  include Controllers::DashboardScoped
  include Controllers::Sortable

  load_sidebar
  after_filter :track_with_tab, except: :show

  def show
    redirect_to for_sale_dashboard_path
  end

  def for_sale
    set_sold_listings(:active)
  end

  def inactive
    set_sold_listings(:inactive)
  end

  def draft
    set_sold_listings(:incomplete)
  end

  def suspended
    set_sold_listings(:suspended)
  end

  def sold
    set_sold_listings(:sold, includes: [:photos, {order: [:buyer, :shipment]}, :shipping_option])
    @funds_waiting = current_user.proceeds_awaiting_settlement
  end

  def bought
    #XXX-buyer-id move back to buyer_id: foo syntax when we drop buyer_id from listing
    @listings = Listing.includes(:order).where('orders.buyer_id = ?', current_user.id).datagrid(params, includes: [:photos, :seller, :order])
  end

protected
  def set_sold_listings(state, options = {})
    @listings = Listing.where(seller_id: current_user.id).with_state(state).
      datagrid(params, includes: options[:includes] || :photos)
  end

  def track_with_tab
    track_usage('dashboard view', tab: params[:action])
  end
end
