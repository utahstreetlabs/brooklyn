class UserStripCollection
  include Enumerable
  include Ladon::Logging

  attr_reader :viewer, :users, :strips, :page, :total, :listings_per_strip
  delegate :each, to: :strips

  # @option +options+ [Integer] :page (0)
  # @option +options+ [Integer] :total (0)
  # @option +options+ [Integer] :listings_per_strip (4)
  def initialize(viewer, users, options = {})
    @viewer = viewer
    @users = users || []
    @page = options.fetch(:page, 0)
    @total = options.fetch(:total, 0)
    @listings_per_strip = options.fetch(:listings_per_strip, 4)
    @strips = Ladon::PaginatableArray.new(@users.map { |u| UserStrip.new(u) }, offset: @page, limit: 100, total: @total,
                                          default_limit: 100)
    eager_fetch_listing_counts
    eager_fetch_liked_counts
    eager_fetch_follower_counts
    eager_fetch_following_counts
    eager_fetch_viewer_follows
    eager_fetch_listings_and_photos
    sort_strips
  end

  def eager_fetch_listing_counts
    if strips.any?
      listing_counts = Listing.visible_counts(strips.map(&:user_id))
      strips.each do |strip|
        strip.listings_count = listing_counts.fetch(strip.user_id, 0)
      end
    end
  end

  def eager_fetch_liked_counts
    if strips.any?
      liked_counts = User.like_counts(strips.map(&:user_id))
      strips.each do |strip|
        strip.liked_count = liked_counts.fetch(strip.user_id, 0)
      end
    end
  end

  def eager_fetch_follower_counts
    if strips.any?
      follower_counts = User.registered_follower_counts(strips.map(&:user_id))
      strips.each do |strip|
        strip.followers_count = follower_counts.fetch(strip.user_id, 0)
      end
    end
  end

  def eager_fetch_following_counts
    if strips.any?
      following_counts = User.registered_following_counts(strips.map(&:user_id))
      strips.each do |strip|
        strip.following_count = following_counts.fetch(strip.user_id, 0)
      end
    end
  end

  def eager_fetch_viewer_follows
    if strips.any?
      viewer_follower_ids = viewer ? viewer.following_follows_for(strips.map(&:user_id)).group_by {|f| f.user_id}.keys : []
      strips.each do |strip|
        strip.viewer_following = strip.user_id.in?(viewer_follower_ids)
      end
    end
  end

  def eager_fetch_listings_and_photos
    if strips.any?
      policy = Users::RecentListingsQueuePolicy.new(count: listings_per_strip)
      policy.choose!(strips.map(&:user))
      strips.each do |strip|
        strip.listings = policy.listings_for_user(strip.user_id)
        strip.photos = policy.photos_for_user(strip.user_id)
      end
    end
  end

  def sort_strips
    search
  end

  def search
    @strips
  end

  def error
    search ? nil : @error
  end

  def last_page?
    max_page = (total.to_i / per_page.to_i).ceil + 1
    error ? true : max_page <= page
  end

  def per_page
    Brooklyn::Application.config.connect.who_to_follow.per_page
  end

  class UserStrip
    attr_accessor :user, :listings_count, :liked_count, :followers_count, :following_count, :viewer_following,
      :listings, :photos

    def initialize(user, attrs = {})
      @user = user
      @listing_counts = attrs.fetch(:listings_count, 0)
      @liked_count = attrs.fetch(:liked_count, 0)
      @followers_count = attrs.fetch(:followers_count, 0)
      @following_count = attrs.fetch(:following_count, 0)
      @viewer_following = attrs.fetch(:viewer_following, false)
      @listings = attrs.fetch(:listings, [])
      @photos = attrs.fetch(:photos, [])
    end

    def user_id
      user.id
    end

    def viewer_following?
      !!@viewer_following
    end
  end
end
