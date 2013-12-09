class Facebook::ConnectionsController < ApplicationController
  skip_requiring_login_only
  skip_enable_autologin
  before_filter :require_not_logged_in
  skip_store_login_redirect
end
