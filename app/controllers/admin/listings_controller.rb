class Admin::ListingsController < AdminController
  include Controllers::AdminScoped
  include Controllers::Admin::ListingScoped

  set_flash_scope 'admin.listings'
  load_listing except: [:index, :show, :edit]
  respond_to :json, only: :feature_on_feature_lists

  def index
    @listings = Listing.datagrid(params, includes: [:category, :seller, :order])
  end

  def show
    @feature_lists = FeatureList.datagrid(params)
    @listing = Listing.includes(:category, :tags, :seller, {order: :buyer}).find(params[:id])
  end

  def edit
    @listing = Listing.includes(:tags).find(params[:id])
    params[:listing] = {tags: @listing.tags.map{|t| t.name}.sort.join(', ')}
  end

  def update
    if @listing.update_attributes(params[:listing], as: :admin)
      redirect_to(admin_listing_path(@listing.id), :notice => localized_flash_message(:updated))
    else
      render(:edit)
    end
  end

  def reactivate
    if @listing.can_reactivate?
      @listing.reactivate!
      set_flash_message(:notice, :reactivated)
    else
      set_flash_message(:alert, :could_not_reactivate)
    end
    redirect_to(admin_listing_path(@listing.id))
  end

  def cancel
    if @listing.can_cancel?
      @listing.cancel!
      set_flash_message(:notice, :cancelled)
    else
      set_flash_message(:alert, :could_not_cancel)
    end
    redirect_to(admin_listing_path(@listing.id))
  end

  def suspend
    if @listing.can_suspend?
      @listing.suspend!
      set_flash_message(:notice, :suspended)
    else
      set_flash_message(:alert, :could_not_suspend)
    end
    redirect_to(admin_listing_path(@listing.id))
  end

  def approve
    if @listing.not_yet_approved?
      @listing.approve!
      set_flash_message(:notice, :approved)
    else
      set_flash_message(:alert, :could_not_approve)
    end
    redirect_to(admin_listing_path(@listing.id))
  end

  def disapprove
    if @listing.not_yet_approved?
      @listing.disapprove!
      set_flash_message(:notice, :disapproved)
    else
      set_flash_message(:alert, :could_not_disapprove)
    end
    redirect_to(admin_listing_path(@listing.id))
  end

  def feature_for_category
    @listing.featured_category_toggle = params[:feature]
    @listing.save!
    if @listing.featured_for_category?(true)
      set_flash_message(:notice, :featured_for_category, category: @listing.category.name)
    else
      set_flash_message(:notice, :not_featured_for_category, category: @listing.category.name)
    end
    redirect_to(admin_listing_path(@listing.id))
  end

  def feature_for_tags
    @listing.featured_tag_ids = params[:tag_ids] || []
    @listing.save!
    if @listing.tag_features(true).any?
      tag_names = @listing.tag_features.map {|f| f.featurable.name}.to_sentence
      set_flash_message(:notice, :featured_for_tags, tags: tag_names, xhr: true)
    else
      set_flash_message(:notice, :not_featured_for_tags, xhr: true)
    end
    respond_to do |format|
      format.js do
        render_jsend(success: {message: "#{flash[:notice]} Reloading page ...",
          redirect: admin_listing_path(@listing.id)})
      end
      format.html do
        redirect_to(admin_listing_path(@listing.id))
      end
    end
  end

  def feature_on_feature_lists
    @feature_lists = FeatureList.datagrid(params)
    @listing.featured_feature_list_ids = params[:feature_list_ids] || []
    @listing.save!
    if @listing.feature_list_features(true).any?
      feature_list_names = @listing.feature_list_features.map {|f| f.featurable.name}.to_sentence
      alert = view_context.bootstrap_flash(:notice, localized_flash_message(:featured_for_feature_lists, feature_lists: feature_list_names))
    else
      alert = view_context.bootstrap_flash(:notice, localized_flash_message(:not_featured_for_feature_lists, feature_lists: feature_list_names))
    end
    render_jsend(success: {
      alert: alert,
      refresh: featured_listings_modal_exhibit(@listing, @feature_lists)
    })
  end

private

  def featured_listings_modal_exhibit(listing, feature_lists)
    Admin::FeatureLists::FeaturedListingsModalExhibit.new(listing, feature_lists, current_user, view_context).render
  end
end
