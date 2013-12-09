class Admin::OffersController < AdminController
  include Controllers::AdminScoped

  set_flash_scope 'admin.offers'
  before_filter only: [:edit] { @offer = Offer.find(params[:id]) }

  def index
    @offers = Datagrid::ArrayDatagrid.new(Offer.all, params)
  end

  def new
    @offer = Offer.new
  end

  def create
    @offer = Offer.new
    @offer.attributes = settable_params(params)
    if @offer.save
      set_flash_message(:notice, :created, id: @offer.id)
      redirect_to(admin_offers_path)
    else
      handle_user_type_errors
      render(:new)
    end
  end

  def edit
  end

  def update
    if @offer = Offer.find(params[:id])
      @offer.attributes = settable_params(params)
      if @offer.save
        set_flash_message(:notice, :updated, id: params[:id])
        redirect_to(admin_offers_path)
      else
        handle_user_type_errors
        render(:edit)
      end
    else
      respond_not_found
    end
  end

  # this field doesn't map into the form, so we just put a flash message up top.
  def handle_user_type_errors
    set_flash_message(:alert, :user_types_error) if @offer.errors.messages[:user_types]
  end

private
  def settable_params(params)
    params[:offer].slice(*Offer.accessible_attributes)
  end
end
