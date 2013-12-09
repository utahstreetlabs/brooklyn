class Admin::TagsController < AdminController
  include Controllers::AdminScoped
  include Controllers::TagScoped

  set_flash_scope 'admin.tags'
  set_tag only: [:show, :edit, :update, :merge, :destroy, :promote]

  def index
    @tags = Tag.primary_tags(with_subtags: true).datagrid(params)
    @listing_counts = ListingTagAttachment.listing_counts(@tags)
  end

  def show
    @features = @tag.features_with_listings
    @listing_counts = ListingTagAttachment.listing_counts(@tag)
    @subtags = Datagrid::ArrayDatagrid.new(@tag.subtags.to_a, params)
  end

  def new
    @tag = Tag.new(internal: true)
  end

  def create
    @tag = Tag.new(params[:tag])
    if @tag.save
      set_flash_message(:notice, :created, :name => @tag.name)
      redirect_to(admin_tag_path(@tag.id))
    else
      render(:new)
    end
  end

  def edit
  end

  def update
    @tag.attributes = params[:tag]
    @tag.slug = nil
    if @tag.save
      set_flash_message(:notice, :updated, :name => @tag.name)
      redirect_to(admin_tag_path(@tag.id))
    else
      render(:edit)
    end
  end

  def merge
    named_tag = Tag.find_by_name(params.fetch(:tag_name)) if params.key?(:tag_name)
    ids = named_tag ? [named_tag.id] : params.fetch(:merge_id, [])
    if ids.empty?
      set_flash_message(:alert, :merge_none_selected)
    else
      @tag.merge(ids)
      set_flash_message(:notice, :merged, name: @tag.name)
    end
    redirect_to(params.key?(:tag_name) ? admin_tag_path(@tag.id) : admin_tags_path)
  end

  def promote
    @tag.promote
    set_flash_message(:notice, :promoted, name: @tag.name)
    redirect_to(admin_tags_path)
  end

  def destroy
    @tag.destroy
    set_flash_message(:notice, :removed, :name => @tag.name)
    redirect_to(@tag.primary?? admin_tags_path : admin_tag_path(@tag.primary_tag_id))
  end

  def destroy_all
    ids = params.fetch(:id, [])
    if ids.empty?
      set_flash_message(:alert, :destroy_all_none_selected)
    else
      Tag.destroy_all(id: ids)
      set_flash_message(:notice, :destroyed_all)
    end
    redirect_to(admin_tags_path)
  end
end
