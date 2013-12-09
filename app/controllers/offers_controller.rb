require 'anchor/models/offer'

class OffersController < ApplicationController
  skip_requiring_login_only only: [:show, :accept]

  before_filter do
    uuid = params[:id] || params[:offer_id]
    @offer = Offer.find_by_uuid(uuid)
    raise ActiveRecord::RecordNotFound, "Couldn't find offer with uuid=#{uuid}" unless @offer
  end

  def show
    track_usage(Events::OfferView.new(@offer))
    with_redirects { render layout: 'application' }
  end

  def accept
    with_redirects do
      options = {buyer_signup: true}
      options[:d] = params[:d] if params[:d]
      redirect_to(auth_path(params[:n], options))
    end
  end

  protected
  def with_redirects
    earned_redirect_path = @offer.destination_url.present? ? @offer.destination_url : root_path
    # either this user is already logged in when they land, or they've been redirected back here on login / register
    if current_user && current_user.registered? && params[:preview].blank?
      @offer.earn(current_user)
      redirect_to(earned_redirect_path)
    else
      session[:offer_id] = @offer.uuid
      # ensure that we go to the dashboard, not back here
      store_login_redirect(earned_redirect_path)
      store_register_redirect(earned_redirect_path)
      yield if block_given?
    end
  end
end
