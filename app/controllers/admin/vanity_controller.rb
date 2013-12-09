class Admin::VanityController < ApplicationController
  before_filter :require_admin

  include Vanity::Rails::Dashboard
end
