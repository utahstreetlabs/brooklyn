class Dashboard::TransactionsController < ApplicationController
  include Controllers::DashboardScoped
  
  layout 'dashboard'
  load_sidebar

  before_filter do
    redirect_to(dashboard_path) unless current_user.balanced_account
  end

  def index
    page = (params[:page] || 1).to_i
    per = (params[:per] || 100).to_i
    @pager = current_user.balanced_transactions(page: page, per: per)
    @history = TransactionHistory.new(current_user, @pager.take(per))
  end
end
