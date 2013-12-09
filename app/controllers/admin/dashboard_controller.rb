class Admin::DashboardController < AdminController
  include Controllers::AdminScoped

  def show
    @stats = AdminStats.new
  end
end
