class Collections::FollowController < ApplicationController
  include Controllers::Jsendable
  include Controllers::CollectionScoped
  respond_to :json
  set_flash_scope 'collections.follow'
  load_collection

  def follow
    current_user.follow_collection!(@collection)
    respond_with_jsend(success: {refresh: new_follow_button(true)})
  end

  def unfollow
    current_user.unfollow_collection!(@collection)
    respond_with_jsend(success: {refresh: new_follow_button(false)})
  end

  protected

  def new_follow_button(following)
    Collections::FollowButtonExhibit.new(@collection, following, current_user, view_context).render
  end
end
