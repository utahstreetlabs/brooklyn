class Listings::External::BookmarkletController < ApplicationController
  include Controllers::ListingScoped

  skip_enable_autologin
  set_listing

  def complete
  end
end
