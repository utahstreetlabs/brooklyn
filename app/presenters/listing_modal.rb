class ListingModal
  include Ladon::Logging

  attr_reader :listing, :viewer, :collection
  delegate :id, :title, :created_at, :seller, :supports_original_price?, :original_price?, :original_price, :price,
           :supports_shipping, :free_shipping, :shipping, :likes_count, :saves_count, :commentable?, :sold?,
           :description, to: :listing

  def initialize(listing, viewer, options = {})
    @listing = listing
    @viewer = viewer
    @collection = options[:collection] || default_collection
  end

  def external?
    listing.respond_to?(:source)
  end

  def domain
    return nil unless external?
    listing.source.domain
  end

  def collection_id
    collection.id if collection
  end

  def collection_owner
    collection.owner if collection
  end

  def thumbnail_listing(id)
    @thumbnail_listing_idx ||= thumbnail_listings.each_with_object({}) { |l, m| m[l.id] = l }
    @thumbnail_listing_idx[id]
  end

  def thumbnail_listings
    @thumbnail_listings ||= begin
      # current listing always goes first
      listings = [listing]
      max = thumbnail_max - 1 # accounts for first listing
      if collection
        listings += collection.find_visible_listings(per: max, excluded_ids: listing.id)
      else
        # Include listings posted by this seller, and if there aren't enough then add listings loved
        # by the seller.
        listings += listing.more_from_this_seller(limit: max)
        if max > listings.size
          listings += Listing.liked_by(seller, per: (max-listings.size), excluded_ids: listing.id)
        end
      end
      listings
    end
  end

  def thumbnail_photos
    @thumbnail_photos ||= begin
      idx = ListingPhoto.find_primaries(thumbnail_listings)
      # Put photo for the current listing in the first position.
      [idx.delete(listing.id)] + idx.values
    end
  end

  def thumbnail_count
    @thumbnail_count ||= thumbnail_photos.count
  end

  def viewer_collections
    viewer.collections if viewer
  end

  def following_collection?
    viewer.following_collection?(collection) if viewer && collection
  end

  def likes_listing?
    viewer.likes?(listing) if viewer
  end

  def saved_listing?
    viewer.saved?(listing) if viewer
  end

  def primary_photo
    @primary_photo ||= listing.photos.first
  end

  def all_comments
    @all_comments ||= listing.comment_summary.comments.values
  end

  def any_comments?
    all_comments.any?
  end

  def total_comments
    all_comments.size
  end

  def comments_to_show
    @comments_to_show ||= all_comments.sort_by(&:created_at).reverse.take(comment_max)
  end

  def invisible_comments?
    total_comments > comment_max
  end

  def commenter(id)
    @commenter_idx ||= User.where(id: comments_to_show.map(&:user_id).compact.uniq).group_by(&:id)
    @commenter_idx[id].first if @commenter_idx.key?(id)
  end

  def thumbnail_max
    self.class.config.thumbnails.count
  end

  def comment_max
    self.class.config.comments.count
  end

  def self.config
    Brooklyn::Application.config.listings.modal
  end

  private
    def default_collection
      collections = listing.seller.saves_for_listing(listing.id).map(&:collection)
      collections.sample if collections.any?
    end
end
