class SecretSeller::ItemsController < ApplicationController
  set_flash_scope 'secret_seller.items'

  def new
    @item = SecretSellerItem.new
  end

  def create
    @item = SecretSellerItem.new(item_params)
    @item.seller = current_user
    if @item.save
      redirect_to(thanks_secret_seller_items_path)
    else
      render(:new)
    end
  end

  def thanks
    # this action is collection-level since 1) we don't need to show anything item-specific on the page and 2) we
    # don't really need to be exposing our db ids in the url, especially since they will be pretty small if we don't
    # get much usage of this feature
  end

  protected
    def item_params
      params[:item].slice(:title, :description, :price, :condition, :photo)
    end
end
