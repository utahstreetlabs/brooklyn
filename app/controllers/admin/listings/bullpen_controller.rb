class Admin::Listings::BullpenController < AdminController
  include Controllers::AdminScoped
  include Controllers::Admin::ListingScoped

  respond_to :json, only: [:approve, :disapprove]
  set_flash_scope 'admin.listings.bullpen'
  load_listing except: :index
  attr_reader :bullpen
  helper_method :bullpen

  def index
    listings = Listing.available_for_approval(includes: :seller, page: params[:page] || 1)
    @bullpen = Bullpen.new(listings)
  end

  def approve
    if @listing.not_yet_approved?
      @listing.approve!
      render_jsend(success: {alert: render_to_string(partial: 'approved_alert', locals: {listing: @listing})})
    else
      render_jsend(fail: {alert: render_to_string(partial: 'failed_alert', locals: {listing: @listing})})
    end
  end

  def disapprove
    if @listing.not_yet_approved?
      @listing.disapprove!
      render_jsend(success: {alert: render_to_string(partial: 'disapproved_alert', locals: {listing: @listing})})
    else
      render_jsend(fail: {alert: render_to_string(partial: 'failed_alert', locals: {listing: @listing})})
    end
  end

  class Bullpen < SimpleDelegator
    attr_reader :listings
    delegate :current_page, :num_pages, :limit_value, to: :listings

    def initialize(listings)
      super(listings.map { |l| Entry.new(l) })
      @listings = listings
      eager_fetch_photos
      eager_fetch_listing_counts
    end

    def eager_fetch_photos
      if any?
        idx = ListingPhoto.find_primaries(map(&:id))
        each { |entry| entry.photo = idx[entry.id] }
      end
    end

    def eager_fetch_listing_counts
      if any?
        idx = Listing.visible_counts(map(&:seller_id).uniq)
        each { |entry| entry.for_sale_count = idx.fetch(entry.seller_id, 0) }
      end
    end

    class Entry < SimpleDelegator
      attr_accessor :photo, :for_sale_count
      delegate :limited_listing_access?, :undetermined_listing_access?, to: :seller

      def initialize(listing, options = {})
        super(listing)
        @photo = options[:photo]
        @for_sale_count = options.fetch(:for_sale_count, 0)
      end
    end
  end
end
