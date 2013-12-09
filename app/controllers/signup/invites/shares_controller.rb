class Signup::Invites::SharesController < ApplicationController
  layout 'signup/invites'
  respond_to :json, only: :create

  def index
  end

  def show
    network = params[:id]
    url_options = {}
    url_options[:fb_ref] = params[:fb_ref] if params[:fb_ref]
    redirect_to(::Invites::IndirectShareContext.share_dialog_url(network, current_user, view_context, url_options))
  end

  def create
    render_jsend(:success)
  end
end
