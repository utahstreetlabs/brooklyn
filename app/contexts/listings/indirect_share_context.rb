require 'context_base'
require 'person'

module Listings
  class IndirectShareContext < ContextBase
    def self.share_dialog_url(network, listing, photo, view_context)
      options = {other_user_profile: listing.seller.person.for_network(network)}
      params = {
        listing: listing.title,
        listing_id: listing.id,
        link: url_helpers.listing_url(listing),
        redirect: url_helpers.callbacks_shared_url,
        price: view_context.number_to_currency(listing.price)
      }
      params[:other_user_username] = options[:other_user_profile] ? options[:other_user_profile].username :
        listing.seller.name
      if Listing.photos_stored_remotely? && photo
        params[:picture] = "http:#{photo.version_url(:small)}"
        params[:large_picture] = "http:#{photo.version_url(:large)}"
      end
      # Note: the sharing_options method may update params in-place.
      sharing_options = Person.sharing_options!(:listing_shared, network, params, options)
      # By default use the listing title for the text.  In the future, extract additional
      # sharing options here.
      params[:text] = sharing_options.fetch(:text, listing.title)
      [:link, :large_picture, :picture, :redirect, :text].each do |p|
        params[p] = url_escape(params[p])
      end
      Network.external_share_dialog_url(network.to_sym, params, options)
    end
  end
end
