class PasswordResetsController < ApplicationController
  skip_requiring_login_only
  before_filter :require_anonymous

  def new
    @user = User.new
  end

  def create
    @user = User.generate_reset_password_token(params[:user][:email])
    if @user.errors.empty?
      if @user.registered?
        self.class.send_email(:reset_password_instructions, @user)
        set_flash_message(:notice, :send_instructions)
      end
      # if the user is not registered, this will kick him into the right place in the registration flow
      redirect_to(root_path)
    else
      render :new
    end
  end

  def show
    @user = User.find_by_reset_password_token(params[:id])
    unless @user
      set_flash_message(:alert, :invalid_token)
      redirect_to(root_path)
    end
  end

  def update
    @user = User.reset_password_by_token(params[:id], params[:user])
    if @user.errors.empty?
      set_flash_message(:notice, :updated)
      sign_in_and_absorb_guest(@user)
      redirect_to(root_path)
    else
      render(:show)
    end
  end
end
