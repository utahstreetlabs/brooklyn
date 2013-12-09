class UserFeedback
  include Enumerable
  include Ladon::Logging

  attr_reader :viewer, :user, :ratings, :feedbacks
  delegate :each, to: :feedbacks
  delegate :current_page, :num_pages, :limit_value, to: :ratings

  def initialize(viewer, user, ratings)
    @viewer = viewer
    @user = user
    @ratings = ratings
    @feedbacks = ratings.map {|r| Feedback.new(r)}
    eager_fetch_orders
    eager_fetch_cancelled_orders
    eager_fetch_listings
    eager_fetch_users
    eager_fetch_photos
  end

  def eager_fetch_orders
    if feedbacks.any?
      order_ids = feedbacks.map { |f| f.rating.order_id }.uniq.compact.sort
      if order_ids.any?
        orders = Order.where(id: order_ids).group_by(&:id)
        feedbacks.each do |feedback|
          feedback.order = orders[feedback.rating.order_id].first if feedback.rating.order_id
        end
      end
    end
  end

  def eager_fetch_cancelled_orders
    if feedbacks.any?
      order_ids = feedbacks.map { |f| f.rating.cancelled_order_id }.uniq.compact.sort
      if order_ids.any?
        orders = CancelledOrder.where(id: order_ids).group_by(&:id)
        feedbacks.each do |feedback|
          feedback.order = orders[feedback.rating.cancelled_order_id].first if feedback.rating.cancelled_order_id
        end
      end
    end
  end

  def eager_fetch_listings
    if feedbacks.any?
      listing_ids = feedbacks.map { |f| f.order.listing_id if f.order }.uniq.compact.sort
      if listing_ids.any?
        listings = Listing.where(id: listing_ids).group_by(&:id)
        feedbacks.each do |feedback|
          feedback.listing = listings[feedback.order.listing_id].first if feedback.order
        end
      end
    end
  end

  def eager_fetch_users
    if feedbacks.any?
      user_ids = (feedbacks.map { |f| f.order.buyer_id if f.order } +
        feedbacks.map { |f| f.listing.seller_id if f.listing }).uniq.compact.sort
      if user_ids.any?
        users = User.where(id: user_ids).group_by(&:id)
        feedbacks.each do |feedback|
          feedback.buyer = users[feedback.order.buyer_id].first if feedback.order
          feedback.seller = users[feedback.listing.seller_id].first if feedback.listing
        end
      end
    end
  end

  def eager_fetch_photos
    if feedbacks.any?
      listing_ids = feedbacks.map { |f| f.listing.id if f.listing }.uniq.compact.sort
      if listing_ids.any?
        photos = ListingPhoto.find_primaries(listing_ids)
        feedbacks.each do |feedback|
          feedback.photo = photos[feedback.listing.id] if feedback.listing
        end
      end
    end
  end

  def self.create(type, viewer, user, options = {})
    case type
    when :buyer then BuyerFeedback.new(viewer, user, options)
    when :seller then SellerFeedback.new(viewer, user, options)
    else raise ArgumentError.new("Unsupported UserFeedback type #{type}")
    end
  end

  class Feedback
    attr_reader :rating
    attr_accessor :order, :listing, :buyer, :seller, :photo
    delegate :purchased_at, to: :rating
    delegate :private?, :public?, to: :order

    def initialize(rating, options = {})
      @rating = rating
      @order = options[:order]
      @listing = options[:listing]
      @buyer = options[:buyer]
      @seller = options[:seller]
      @photo = options[:photo]
    end

    def price
      listing.total_price
    end

    def rated_positive?
      rating.positive?
    end

    def rated_negative?
      rating.negative?
    end

    def rated_neutral?
      rating.neutral?
    end

    def failed_due_to_non_shipment?
      rating.failure_reason == Order::FailureReasons::NEVER_SHIPPED
    end

    def sold_by?(user)
      seller == user
    end

    def bought_by?(user)
      buyer == user
    end

    def visible_to?(user)
      public? || bought_by?(user) || sold_by?(user)
    end
  end
end

class BuyerFeedback < UserFeedback
  def initialize(viewer, user, options = {})
    ratings = options.delete(:ratings)
    unless ratings
      options[:per] ||= Brooklyn::Application.config.users.feedback.per_page
      ratings = user == viewer ? BuyerRating.find_all_for_user(user.id, options) :
        BuyerRating.find_positive_for_user(user.id, options)
    end
    super(viewer, user, ratings)
  end
end

class SellerFeedback < UserFeedback
  def initialize(viewer, user, options = {})
    ratings = options.delete(:ratings)
    unless ratings
      options[:per] ||= Brooklyn::Application.config.users.feedback.per_page
      ratings = SellerRating.find_all_for_user(user.id, options)
    end
    super(viewer, user, ratings)
  end
end
