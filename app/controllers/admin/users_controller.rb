class Admin::UsersController < ApplicationController
  layout 'admin'
  set_flash_scope 'admin.users'
  respond_to :json, only: :typeahead
  load_resource
  authorize_resource except: :deactivate

  def index
    @users = User.datagrid(params)
  end

  def typeahead
    users = User.datagrid(params)
    render_jsend(success: {
      matches: users.map { |u| {slug: u.slug, name: u.name, email: u.email} }
    })
  end

  def new
    @user = User.new
  end

  def create
    @user = User.create_registered_user(create_params)
    if @user.errors.empty?
      set_flash_message(:notice, :created, name: @user.name)
      redirect_to(admin_user_path(@user.id))
    else
      render(:new)
    end
  end

  def update
    if @user.update_attributes(update_params)
      set_flash_message(:notice, :updated, name: @user.name)
      redirect_to(admin_user_path(@user.id))
    else
      render(:edit)
    end
  end

  def deactivate
    authorize!(:deactivate, @user)
    @user.deactivate!
    set_flash_message(:notice, :deactivated, name: @user.name)
    redirect_to(admin_user_path(@user.id))
  end

  def reactivate
    authorize!(:reactivate, @user)
    @user.reactivate!
    set_flash_message(:notice, :reactivated, name: @user.name)
    redirect_to(admin_user_path(@user.id))
  end

  def destroy
    if @user.destroy
      set_flash_message(:notice, :destroyed, name: @user.name)
      redirect_to(admin_users_path)
    else
      set_flash_message(:alert, :destroy_failed, name: @user.name)
      redirect_to(admin_user_path(@user.id))
    end
  end

  protected
    def create_params
      params[:user].slice(:firstname, :lastname, :email, :password, :password_confirmation)
    end

    def update_params
      params[:user].slice(:firstname, :lastname, :name, :slug, :web_site_enabled, :listing_access, :needs_onboarding)
    end
end
