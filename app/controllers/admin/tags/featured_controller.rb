class Admin::Tags::FeaturedController < AdminController
  include Controllers::AdminScoped
  include Controllers::TagScoped
  include Controllers::Jsendable

  set_flash_scope 'admin.tags.featured'

  set_tag
  before_filter :set_feature

  def reorder
    @feature.insert_at(params[:position].to_i)
    respond_to do |format|
      format.json { render_jsend featured_listings(@tag) }
    end
  end

  def destroy
    @tag.delete_feature(@feature)
    set_flash_message(:notice, :removed, listing: @feature.listing.title, tag: @tag.name)
    redirect_to(admin_tag_path(@tag.id))
  end

  protected
    def set_feature
      @feature = @tag.find_feature(params[:id])
    end

    def featured_listings(tag)
      result = render_to_string(partial: '/admin/tags/featured_listings.html',
        locals: {tag: tag, features: tag.features_with_listings})
      {success: {result: result}}
    end
end
