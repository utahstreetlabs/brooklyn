require 'datagrid'

class Collection < ActiveRecord::Base
  include Sluggable
  include Stats::Trackable
  include Collections::Autofollowable

  module Types
    GENERIC = 1
    HAVE    = 2
    WANT    = 3

    def self.all
      [GENERIC, HAVE, WANT]
    end

    def self.name(code)
      case code
      when GENERIC then :generic
      when HAVE then :have
      when WANT then :want
      else raise ArgumentError.new("Unknown type code #{code}")
      end
    end
  end

  MAX_COLLECTIONS = Brooklyn::Application.config.collections.max_per_user
  MAX_NAME_LENGTH = 50

  belongs_to :user
  has_many :listing_collection_attachments, dependent: :destroy
  has_many :listings, through: :listing_collection_attachments,
    order: "#{ListingCollectionAttachment.quoted_table_name}.updated_at DESC"
  has_many :follows, class_name: 'CollectionFollow', dependent: :destroy
  has_many :followers, through: :follows
  has_slug :slug, attribute: :name, max_length: 100, sluggable_max_length: MAX_NAME_LENGTH,
    uniqueness_scope: {scope: :user_id}, unique_suffix: true

  default_sort_column :name
  search_columns :name

  attr_accessor :suppress_tracking
  attr_accessible :name, :type_code, :editable, :suppress_tracking
  validates :name, format: {with: /^[a-zA-Z0-9 \.']+$/}, allow_blank: true
  validate :max_per_user, on: :create

  scope :new_this_month, where('MONTH(created_at) = MONTH(NOW())').where('YEAR(created_at) = YEAR(NOW())')
  scope :new_today, new_this_month.where('DAY(created_at) = DAY(NOW())')

  def max_per_user
    if user.collections.count >= MAX_COLLECTIONS
      errors[:base] << I18n.translate(:too_many_collections, scope: 'activerecord.errors.models.collection.attributes.user', max: MAX_COLLECTIONS)
    end
  end

  def add_listing(listing)
    listings << listing
  rescue ActiveRecord::RecordNotUnique
    # the listing is already in the collection. cool.
  end

  def add_listings(ids)
    ids = Array.wrap(ids).compact
    if ids.any?
      # don't bother to wrap in a transaction. add_listing is idempotent so if it raises and then the operation is
      # retried it won't raise for the set of listings that were successfully saved in the previous attempt.
      Listing.where(id: ids).find_each do |listing|
        add_listing(listing)
      end
    end
  end

  def remove_listing(listing)
    (listings.delete(listing)) and
      track_usage(Events::UnsaveListing.new(listing, self))
  end

  def listing_count
    c = read_attribute(:listing_count)
    if c.nil?
      Collection.reset_counters(id, :listing_collection_attachments)
      self.reload.listing_count
    else
      c
    end
  end

  def follower_count
    c = read_attribute(:follower_count)
    if c.nil?
      Collection.reset_counters(id, :follows)
      self.reload.follower_count
    else
      c
    end
  end

  def owner
    user
  end

  def owned_by?(other)
    user_id == other.id
  end

  # @option options [Integer] :page (1)
  # @option options [Integer] :per (+#items_per_page+)
  # @option options [Array] :excluded_ids ids of listings to exclude
  # @return [ActiveRecord::Relation]
  def find_listings(options = {})
    relation = listings.page(options.fetch(:page, 1)).per(options.fetch(:per, self.class.items_per_page))
    if options[:excluded_ids].present?
      relation = relation.where("#{Listing.quoted_table_name}.id NOT IN (?)", Array.wrap(options[:excluded_ids]))
    end
    relation
  end

  # @return [ActiveRecord::Relation]
  # @see #find_listings
  def find_visible_listings(options = {})
    logger.debug "Finding visible listings for collection #{self.id}"
    find_listings(options).where(state: [:active, :sold])
  end

  def type
    Types.name(type_code)
  end

  Types.all.each do |code| # :nodoc:
    # Add predicate methods that tell whether or not the collection is of a given type.
    #
    #   ruby-1.9.3-p0 :019 > Collection.new(type_code: Collection::Types::HAVE).have?
    #   true
    define_method("#{Types.name(code)}?") do
      type_code == code
    end
  end

  # Returns listings that are good candidates for adding to this collection.
  #
  # @option options [Integer] (20) :count the maximum number of listings to return
  # @return [Array]
  # @see +Listing#find_suggested_for_collection+
  def find_suggested_listings(options = {})
    Listing.find_suggested_for_collection(self, options)
  end

  def suppress_tracking?
    !!suppress_tracking
  end

  def self.find_collections_by_slug(slugs, options = {})
    relation = where(slug: Array.wrap(slugs).compact)
    relation = relation.where(user_id: options[:user].id) if options[:user]
    relation
  end

  def self.find_named_for_user(name, user)
    where(name: name, user_id: user.id).first
  end

  def self.named_exists_for_user?(name, user)
    where(name: name, user_id: user.id).count > 0
  end

  def self.create_defaults_for(user)
    transaction do
      default_collection_specs.each do |spec|
        # bypassing protection lets us set the slug without making it generally accessible
        user.collections.create!(spec.merge(suppress_tracking: true), without_protection: true)
      end
    end
  end

  # Returns the visible listings added to each of +collections+ in reverse chronological order.
  #
  # @option options [Integer] limit (+nil+) if provided, return up to this many listings per collection
  # @option options [Boolean] ids_only (+false+) if provided, return only listing ids rather than full listings
  # @return [Hash] a map of collection ids to arrays of listing ids
  def self.recently_added_visible_listings(collections, options = {})
    # XXX: get all listing ids in one query: this is a hard SQL problem, and we haven't yet figured
    #      how to do it in one query. it does cause an n+1 issue on the collections page though, so
    #      if that starts biting us in the ass we might should return to this.
    # XXX: this problem is now present on the home page as well
    collections.each_with_object({}) do |collection, m|
      relation = collection.listings.where(state: [:active, :sold]).
        order("#{Listing.quoted_table_name}.created_at DESC")
      if options[:ids_only]
        relation = relation.select("#{Listing.quoted_table_name}.id")
      end
      if options[:limit]
        relation = relation.limit(options[:limit])
      end
      m[collection.id] = if options[:ids_only]
        relation.map(&:id)
      else
        relation.to_a
      end
    end
  end

  # Returns the count of listings in each collection identified by +collection_ids+.
  #
  # @return [Hash] a map of collection ids to listing counts
  def self.visible_counts(collection_ids)
    collection_ids = Array.wrap(collection_ids).compact.uniq
    ListingCollectionAttachment.
      joins(:listing).
      where(listings: {state: [:active, :sold]}).
      select('collection_id, count(*) AS listing_count').
      where(collection_id: collection_ids).
      group(:collection_id).
      each_with_object({}) { |a, m| m[a.collection_id] = a.listing_count }
  end

  def self.items_per_page
    config.items_per_page
  end

  def self.default_collection_specs
    [
      {name: I18n.t('models.collection.defaults.name.have'),    type_code: Types::HAVE,    slug: 'haves',   editable: false},
      {name: I18n.t('models.collection.defaults.name.want'),    type_code: Types::WANT,    slug: 'wants',   editable: false},
      {name: I18n.t('models.collection.defaults.name.awesome'), type_code: Types::GENERIC, slug: 'awesome', editable: false},
    ]
  end

  # Returns the most collections with the most follows.
  #
  # @option options [Integer] :window if provided, specifies that only follows created up to this many seconds before
  #                                   now should be considered
  # @option options [Integer] :limit (50) the maximum number of collections to return
  # @option options [Array] :exclude_owners +User+s or ids whose collections should not be considered
  # @return [ActiveRecord::Relation]
  def self.find_most_followed(options = {})
    limit = options.fetch(:limit, 50)
    relation = joins(:follows).
                 select("#{quoted_table_name}.*, COUNT(*) AS follow_count").
                 group("#{CollectionFollow.quoted_table_name}.collection_id").
                 order("follow_count DESC").
                 limit(limit)
    if options[:window].present?
      to_time = Time.zone.now
      from_time = to_time - options[:window].seconds
      relation = relation.where("#{CollectionFollow.quoted_table_name}.created_at BETWEEN ? AND ?", from_time, to_time)
      logger.debug("Finding #{limit} most followed collections between #{from_time} and #{to_time}")
    else
      logger.debug("Finding #{limit} most followed collections of all time")
    end
    if options[:min_listings].present?
      relation = relation.where("listing_count >= ?", options[:min_listings])
    end
    if options[:exclude_owners].present?
      excluded_owner_ids = Array.wrap(options[:exclude_owners]).compact.map { |v| v.is_a?(User) ? v.id : v }
      relation = relation.where("#{quoted_table_name}.user_id NOT IN (?)", excluded_owner_ids)
    end
    relation
  end

  def self.config
    Brooklyn::Application.config.collections
  end

  before_save on: :update do
    # uneditable collections can have custom slugs
    if self.name_changed? && editable?
      self.reset_slug
      self.slugify
    end
  end

  before_validation do
    self.type_code ||= Types::GENERIC
  end

  before_validation on: :update do
    readonly! unless editable?
  end

  after_commit on: :create do
    user.follow_collection!(self)
    unless suppress_tracking?
      track_usage(Events::CollectionCreate.new(self))
    end
  end

  after_update do
    unless suppress_tracking?
      track_usage(Events::CollectionUpdate.new(self))
    end
  end

  after_destroy do
    unless suppress_tracking?
      track_usage(Events::CollectionDelete.new(self))
    end
  end
end
