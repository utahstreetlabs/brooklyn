class Admin::InterestsController < ApplicationController
  layout 'admin'
  set_flash_scope 'admin.interests'
  load_resource except: [:create, :add_to_onboarding, :remove_from_onboarding, :destroy_all]
  authorize_resource except: [:add_to_onboarding, :remove_from_onboarding, :destroy_all]

  def index
    @interests = @interests.by_name
    @suggested_counts = Interest.suggested_user_list_counts
    @interested_counts = Interest.interested_user_list_counts
    @autofollow_counts= Interest.autofollow_collection_list_counts
  end

  def new
    @interest = Interest.new({onboarding: true}, as: :admin)
  end

  def create
    @interest = Interest.new(interest_params, as: :admin)
    if @interest.save
      set_flash_message(:notice, :created, name: @interest.name)
      redirect_to(admin_interests_path)
    else
      render(:new)
    end
  end

  def edit
  end

  def update
    if @interest.update_attributes(interest_params, as: :admin)
      redirect_to(admin_interests_path, :notice => localized_flash_message(:updated, name: @interest.name))
    else
      render(:edit)
    end
  end

  def show
    @users = @interest.suggested_user_list
    @collections = @interest.autofollow_collection_list
  end

  def destroy
    @interest.destroy
    set_flash_message(:notice, :destroyed, name: @interest.name)
    redirect_to(admin_interests_path)
  end

  def add_all_to_onboarding
    authorize!(:update, Interest)
    if params[:id]
      Interest.add_to_onboarding_list!(params[:id])
      set_flash_message(:notice, :all_added_to_onboarding)
    else
      set_flash_message(:alert, :none_selected_add_all_to_onboarding)
    end
    redirect_to(admin_interests_path)
  end

  def remove_all_from_onboarding
    authorize!(:update, Interest)
    if params[:id]
      Interest.remove_from_onboarding_list!(params[:id])
      set_flash_message(:notice, :all_removed_from_onboarding)
    else
      set_flash_message(:alert, :none_selected_remove_all_from_onboarding)
    end
    redirect_to(admin_interests_path)
  end

  def destroy_all
    authorize!(:destroy, Interest)
    if params[:id]
      Interest.destroy_all(id: params[:id])
      set_flash_message(:notice, :destroyed_all)
    else
      set_flash_message(:alert, :none_selected_destroy_all)
    end
    redirect_to(admin_interests_path)
  end

  protected
    def interest_params
      params[:interest].slice(:name, :gender, :cover_photo, :onboarding)
    end
end
