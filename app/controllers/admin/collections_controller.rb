class Admin::CollectionsController < AdminController
  include Controllers::AdminScoped
  set_flash_scope 'admin.collections'
  load_resource
  authorize_resource

  def index
    @collections = Collection.datagrid(params, includes: [:user, :autofollows])
  end

  def show
    @collection = Collection.includes(:user).find(params[:id])
  end

  def edit
  end

  def update
    @collection.attributes = params[:collection]
    if @collection.save
      set_flash_message(:notice, :updated, :name => @collection.name)
      redirect_to(admin_collection_path(@collection.id))
    else
      render(:edit)
    end
  end

  def destroy
    @collection.destroy
    set_flash_message(:notice, :destroyed, :name => @collection.name)
    redirect_to(admin_collections_path)
  end
end
