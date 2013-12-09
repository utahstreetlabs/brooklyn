class Admin::Collections::AutofollowsController < ApplicationController
  respond_to :json
  set_flash_scope 'admin.collections.autofollows'
  load_and_authorize_resource :collection, class: 'Collection'

  def set
    authorize!(:manage, CollectionAutofollow)
    params[:collection] ||= HashWithIndifferentAccess.new
    @collection.autofollow_for_interests!(params[:collection][:autofollowed_interest_ids])
    collection_exhibit = Admin::Collections::Autofollows::CollectionExhibit.new(@collection, current_user, view_context)
    alert = view_context.admin_notice(:success, localized_flash_message(:set, collection: @collection.name))
    render_jsend(success: {alert: alert, refresh: collection_exhibit.render})
  end
end
