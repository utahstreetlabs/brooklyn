class Listings::BookmarkletController < ApplicationController
  skip_requiring_login_only

  def show
    redirect_to(login_path(source: :bookmarklet)) unless logged_in?
  end
end
