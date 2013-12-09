require 'active_support/concern'

module Users
  # A listing must be explicitly approved for inclusion in the Everything feed and New Arrivals browse page.
  #
  # Listings created by users with full access are automatically approved when activated. Those created by
  # users with no access are automatically disapproved when activated. Those created by users with undetermined or
  # limited access require manual approval by administrators.
  #
  # Expects the including class to provide the methods that ActiveRecord would for the following attributes:
  #
  # * +listing_access+ (integer, nullable)
  module ListingAccess
    extend ActiveSupport::Concern

    module ListingAccess
      FULL = 1
      LIMITED = 0
      NONE = -1
    end

    def full_listing_access?
      listing_access == ListingAccess::FULL
    end

    def limited_listing_access?
      listing_access == ListingAccess::LIMITED
    end

    def no_listing_access?
      listing_access == ListingAccess::NONE
    end

    def undetermined_listing_access?
      listing_access.nil?
    end

    # @return [ActiveRecord::Relation]
    def listings_available_for_approval
      Listing.available_for_approval(seller_id: self.id)
    end

    def approve_all_available_listings
      Listing.approve_all(listings_available_for_approval)
    end

    def disapprove_all_available_listings
      Listing.disapprove_all(listings_available_for_approval)
    end

    # If the user's listing access is dirty, approves all not yet approved listings if the user now has full access,
    # or disapproves them all if the user now has no access.
    #
    # XXX: this should happen asynchronously eventually so as to not lock the user record while updating the associated
    # listings, but to do that safely, we need a separate api method for changing the user's listing access and
    # triggering the async events that saves only :listing_access and therefore won't be rolled back by eg another
    # attribute value being invalid. this in turn depends on the admin ui being designed to update the user's listing
    # access independently of any other attributes.
    def clear_bullpen_if_necessary(&block)
      changed = listing_access_changed?
      yield if block_given?
      if changed
        if full_listing_access?
          approve_all_available_listings
        elsif no_listing_access?
          disapprove_all_available_listings
        end
      end
    end

    included do
      around_update :clear_bullpen_if_necessary
    end
  end
end
