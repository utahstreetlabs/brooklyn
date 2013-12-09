class Admin::Interests::CollectionsController < ApplicationController
  set_flash_scope 'admin.interests.collections'
  load_and_authorize_resource :interest, class: 'Interest'
  load_and_authorize_resource :collection, class: 'Collection'

  def destroy
    @interest.remove_from_autofollow_collection_list(@collection)
    set_flash_message(:notice, :destroyed, collection: @collection.name)
    redirect_to(admin_interest_path(@interest))
  end
end
