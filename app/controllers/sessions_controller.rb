class SessionsController < ApplicationController
  skip_requiring_login_only
  skip_checking_session_expiration
  skip_updating_last_accessed only: :destroy
  skip_store_login_redirect

  before_filter :require_not_logged_in, :only => [:create, :new]
  before_filter :store_redirect, :only => :new
  before_filter :clear_stash, only: :destroy # XXX: better as a session observer callback

  respond_to :json

  def new
    @login = Login.new(email: params[:email], remember_me: true)
  end

  def create
    @login = Login.new(login_params)
    if @login.valid?
      begin_login_session(@login)
      respond_to do |format|
        format.json { render_jsend(:success) }
        format.all do
          if @login.user.needs_onboarding?
            onboard(@login.user)
          else
            redirect_after_login
          end
        end
      end
    else
      respond_to do |format|
        format.json { render_jsend(fail: {errors: @login.errors.full_messages}) }
        format.all { render(:new) }
      end
    end
  end

  def destroy
    end_session(current_user)
    respond_to do |format|
      format.json { render_jsend(:success) }
      format.all { redirect_to(controller: :home, action: :index, noal: true) }
    end
  end

  protected
    def login_params
      params[:login].slice(:email, :password, :remember_me, :facebook_token, :facebook_signed)
    end

    # XXX: would make more sense for these methods, as well as the method that begins an omniauth session and any
    # other session-related methods, to be on the Session model (with a controller observer to do controller-related
    # stuff). that's more refactoring than I want to do right now, though.

    def begin_login_session(login)
      sign_in_and_absorb_guest(login.user)
      begin
        login.user.update_oauth_token(:facebook, signed: login.facebook_signed) if login.facebook_signed.present?
      rescue InvalidCredentials
        # XXX: silently ignore mismatches, generally caused by someone logging in as one user while they have another
        # user's facebook cookie in their browser.
      end
      login.user.remember_me! if login.remember_me?
      track_usage(:login, user: login.user)
    end

    def end_session(user)
      user.forget_me! if user
      sign_out
    end

    def onboard(user)
      set_flash_message(:notice, :re_onboarding)
      self.signup_just_registered = true
      self.signup_flow_destination = redirect_path(:login)
      reset_redirect_for(:login)
      user.update_attribute(:needs_onboarding, false)
      redirect_to(signup_buyer_interests_path)
    end
end
