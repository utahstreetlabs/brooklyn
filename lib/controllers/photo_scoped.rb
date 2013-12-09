module Controllers
  # Provides common behaviors for controllers that are scoped to a listing.
  module PhotoScoped
    extend ActiveSupport::Concern

    def photos_jsend
      locals = {listing: @listing, photos: @listing.photos.all}
      {success: {photos: render_to_string(partial: '/listings/photo_list.html', locals: locals),
          update: render_to_string(partial: '/listings/photo_update_forms.html', locals: locals)}}
    end
  end
end
