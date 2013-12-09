class Listings::FeaturesController < ApplicationController
  include Controllers::ListingScoped
  include Controllers::Jsendable
  respond_to :json
  set_flash_scope 'listings.features'
  set_listing

  before_filter :require_admin

  def update
    @listing.featured_category_toggle = params[:category_id].present?
    @listing.featured_tag_ids = params.fetch(:tag_ids, [])
    @listing.featured_feature_list_ids = params.fetch(:feature_list_ids, [])
    @listing.save or
      return respond_with_jsend(fail: {
        modal: feature_listing_modal_contents_exhibit(@listing),
        errors: listing.errors
      })
    # Force these related associations to refresh after save so they're updated
    # when generating the success modal.
    @listing.tag_features(true)
    @listing.feature_list_features(true)
    @listing.category_feature(true)
    respond_to_feature
  end

  def feature_modal
    respond_with_jsend(success: {
      modal: feature_listing_modal_contents_exhibit(@listing)
    })
  end

protected

  def respond_to_feature
    respond_with_jsend(success: {
      followupModal: feature_listing_success_modal_exhibit(@listing),
      replace: feature_listing_button_exhibit(@listing)
    })
  end

  def feature_listing_modal_contents_exhibit(listing)
    Listings::FeatureModalExhibit.new(listing, current_user, view_context).render
  end

  def feature_listing_success_modal_exhibit(listing)
    Listings::FeatureSuccessModalExhibit.new(listing, current_user, view_context).render
  end

  def feature_listing_button_exhibit(listing)
    Listings::FeatureButtonExhibit.new(listing, current_user, view_context).render
  end
end
