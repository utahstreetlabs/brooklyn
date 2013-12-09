class Admin::Listings::LoveEmailsController < AdminController
  include Controllers::AdminScoped
  include Controllers::Admin::ListingScoped

  set_flash_scope 'admin.listings.love_emails'
  load_listing

  def create
    if current_user.likes?(@listing)
      Listings::AfterLikeJob.email_liked(@listing, current_user)
      set_flash_message(:notice, :created)
    else
      set_flash_message(:alert, :error_creating)
    end
    redirect_to(admin_listing_path(@listing.id))
  end
end
