class Admin::Users::ListingsController < ApplicationController
  layout 'admin'

  load_and_authorize_resource :user

  # :through assumes user.listings exists, so we can't use load_and_authorize_resource.
  load_resource :listing, only: :show
  authorize_resource :listing, only: :show

  def show
    @feature_lists = FeatureList.datagrid(params)
  end

  def index
    authorize! :index, Listing
    @listings = Listing.where(seller_id: params[:user_id])
    @listings = @listings.datagrid(params, includes: [:category, :seller, :order])
  end
end
