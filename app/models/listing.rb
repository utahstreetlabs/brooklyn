require 'anchor/models/listing'
require 'brooklyn/sprayer'
require 'datagrid'
require 'state_machine'
require 'active_model/warnings'

class OrderAlreadyInitiated < ActiveRecord::RecordNotSaved; end

class HasPhotosValidator < ActiveModel::Validator
  def validate(listing)
    unless listing.has_photos?
      listing.errors.add(:photos, I18n.translate('activerecord.errors.models.listing.attributes.photos.empty'))
    end
  end
end

class SellerStateValidator < ActiveModel::Validator
  def validate(listing)
    if listing.incomplete? or listing.inactive?
      unless listing.seller.guest? or listing.seller.registered?
        listing.errors.add(:seller, I18n.translate(:not_guest_or_registered,
            scope: 'activerecord.errors.models.listing.attributes.seller'))
      end
    else
      unless listing.seller.registered?
        listing.errors.add(:seller, I18n.translate(:not_registered,
          scope: 'activerecord.errors.models.listing.attributes.seller'))
      end
    end
  end
end

class DimensionsValidator < ActiveModel::Validator
  def validate(listing)
    valid_values = listing.valid_dimension_values
    if listing.dimension_values
      listing.dimension_values.each do |value|
        unless valid_values.include? value
          listing.errors.add(:dimension_values, I18n.translate('activerecord.errors.models.listing.attributes.dimension_values.invalid'))
        end
      end
    end
  end
end

class SizeValidator < ActiveModel::Validator
  def validate(listing)
    if listing.read_attribute(:size_name).present?
      unless listing.size
        listing.errors.add(:size_name, I18n.translate('activerecord.errors.models.listing.attributes.size.invalid'))
      end
    end
  end
end

class ShippingOptionValidator < ActiveModel::Validator
  def validate(listing)
    if listing.shipping_option
      unless listing.prepaid_shipping_covered?(listing.shipping_option)
        listing.errors.add(:shipping_option_code, :invalid)
      end
    end
  end
end

class GreaterThanPriceValidator < ActiveModel::Validator
  def validate(listing)
    if listing.original_price.present? &&
      listing.original_price.to_i < listing.price.to_i
      listing.errors.add(:original_price,
        I18n.translate(:less_than_price,
          scope: 'listings.new_pricing_fields.price.original_price_field'
        )
      )
    end
  end
end

class Listing < ActiveRecord::Base
  include Sluggable
  include ApiAccessable
  include Likeable
  include Brooklyn::Observable
  include Brooklyn::UniqueIndexEnforceable
  include Brooklyn::Sprayer
  include Ladon::ErrorHandling
  include Listings::Approval
  include Listings::Api
  include Listings::Comments
  include Listings::Collections
  include Listings::Searchable
  include ActiveModel::Warnings

  PLACEHOLDER_TITLE = 'New Listing'
  DEFAULT_PRICING_VERSION = Brooklyn::PricingScheme.current_version
  HANDLING_TIMES = [4, 7, 10, 15, 20, 30]
  MINIMUM_PRICE = Brooklyn::Application.config.pricing.minimum

  # allow slugs to be longer than titles to account for multiple listings with the same title having unique suffixes
  has_slug :slug, attribute: :title, unique_suffix: true, max_length: 100, sluggable_max_length: 80,
    validate_sluggable_if: lambda { self.new_record? or self.title_changed? }
  has_uuid

  belongs_to :seller, :class_name => 'User'
  belongs_to :item
  belongs_to :category
  has_many :dimension_value_attachments, :class_name => 'DimensionValueListingAttachment', :dependent => :destroy
  has_many :dimension_values, through: :dimension_value_attachments,
    after_add: Proc.new { |l,dv| l.notify_observers(:after_dimension_value_add, dv) },
    after_remove: Proc.new { |l,dv| l.notify_observers(:after_dimension_value_remove, dv) }
  has_many :tag_attachments, :class_name => 'ListingTagAttachment', :dependent => :destroy
  has_many :tags, :through => :tag_attachments, before_remove: :unfeature_for_tag,
    after_add: Proc.new { |l,t| l.notify_observers(:after_tag_add, t) },
    after_remove: Proc.new { |l,t| l.notify_observers(:after_tag_remove, t) }
  belongs_to :size, class_name: 'Tag'
  belongs_to :brand, class_name: 'Tag'
  has_many :flags, :class_name => 'ListingFlag', :dependent => :destroy
  has_one :order, :dependent => :destroy
  # the after_destroy on Order needs to run before photos are destroyed, so photos needs to be declared here
  has_many :photos, :class_name => 'ListingPhoto', :dependent => :destroy, :order => 'position'
  has_many :cancelled_orders, :dependent => :destroy
  has_many :features, class_name: 'ListingFeature', dependent: :destroy
  has_one :category_feature, class_name: 'ListingFeature', conditions: {featurable_type: 'Category'}
  has_many :tag_features, class_name: 'ListingFeature', conditions: {featurable_type: 'Tag'}
  has_many :feature_list_features, class_name: 'ListingFeature', conditions: {featurable_type: 'FeatureList'}
  has_many :featured_in_tags, class_name: 'Tag', through: :tag_features, source: :featurable, source_type: 'Tag'
  has_many :featured_in_feature_lists, class_name: 'FeatureList', through: :feature_list_features,
    source: :featurable, source_type: 'FeatureList'
  has_one :shipping_option, dependent: :destroy
  has_one :return_address, class_name: 'PostalAddress', dependent: :destroy
  has_many :offers, class_name: 'ListingOffer', dependent: :destroy

  normalize_attribute :title, :with => [:squish]

  # synthetic attributes used to create and delete features
  attr_accessor :featured_category_toggle, :featured_tag_ids, :featured_feature_list_ids

  # synthetic attributes used to track listing activation
  attr_accessor :first_seller_activation, :first_activation

  state_machine :state, :initial => :incomplete do
    # incomplete:   in the process of being created
    # inactive:     listable but not able to be purchased
    # active:       able to be purchased
    # suspended:    suspended by an admin
    # sold:         purchased by another user
    # cancelled:    removed by seller

    # the listing has enough information to be listable, but has yet to be published
    event :complete do
      transition :incomplete => :inactive
    end

    # the listing no longer has enough information to be listable
    before_transition on: :uncomplete do |listing|
      listing.activated_at = nil
    end
    event :uncomplete do
      transition [:active, :inactive] => :incomplete
    end
    after_transition on: :uncomplete do |listing|
      listing.features.clear
      listing.evict_from_seller_recent_cache
      Listings::AfterUncompletionJob.enqueue(listing.id)
    end

    # publishes the listing
    before_transition on: :activate do |listing|
      listing.activated_at = Time.now
      # let the transition persist approval or disapproval rather than doing it explicitly. this keeps us from having
      # one update for the activation and a second update for the approval/disapproval, which also keeps us from
      # trigger two reindexes.
      if listing.seller.full_listing_access?
        listing.approve!(persist: false)
      elsif listing.seller.no_listing_access?
        listing.disapprove!(persist: false)
      else
        # the listing must be approved manually by an administrator
      end
      listing.first_seller_activation = true unless listing.seller.has_ever_activated_a_listing?
      unless listing.has_been_activated?
        listing.first_activation = true
        listing.has_been_activated = true
      end
    end
    event :activate do
      transition [:inactive] => :active
    end
    after_transition on: :activate do |listing|
      listing.add_to_seller_recent_cache
      Users::AfterFirstActivationJob.enqueue(listing.seller.id) if listing.first_seller_activation
      Listings::AfterActivationJob.enqueue(listing.id, first_activation: listing.first_activation)
    end

    # unpublishes the listing
    before_transition on: :deactivate do |listing|
      listing.activated_at = nil
    end
    event :deactivate do
      transition :active => :inactive
    end
    after_transition on: :deactivate do |listing|
      listing.features.clear
      listing.evict_from_seller_recent_cache
      Listings::AfterDeactivationJob.enqueue(listing.id)
    end

    # unpublishes the listing for administrative reasons
    before_transition on: :suspend do |listing|
      # leave activated_at set so we can compare that timestamp to suspended_at
      listing.suspended_at = Time.now
    end
    event :suspend do
      transition [:incomplete, :inactive, :active] => :suspended
    end
    after_transition :on => :suspend do |listing|
      listing.order.cancel! if listing.order
      listing.features.clear
      listing.evict_from_seller_recent_cache
      Listings::AfterSuspensionJob.enqueue(listing.id)
    end

    # republishes the listing after administrative concerns have been addressed
    # XXX: rename to reinstate to distinguish from activate/deactivate
    before_transition on: :reactivate do |listing|
      listing.suspended_at = nil
      listing.activated_at = Time.now
    end
    event :reactivate do
      transition [:suspended] => :active
    end
    after_transition on: :reactivate do |listing|
      listing.add_to_seller_recent_cache
      Listings::AfterReactivationJob.enqueue(listing.id)
    end

    # soft-deletes the listing - it can never be republished
    before_transition on: :cancel do |listing|
      listing.cancelled_at = Time.now
    end
    event :cancel do
      transition [:incomplete, :inactive, :active, :suspended] => :cancelled
    end
    after_transition :on => :cancel do |listing|
      listing.order.cancel! if listing.order
      listing.features.clear
      listing.evict_from_seller_recent_cache
      Listings::AfterCancellationJob.enqueue(listing.id)
    end

    # indicates the listing has an outstanding confirmed order
    before_transition on: :sell do |listing|
      # lock the row to ensure we never double sell
      listing.reload(lock: true)
      raise ActiveRecord::Rollback if listing.sold?
      listing.sold_at = Time.now
    end
    event :sell do
      transition :active => :sold
    end
    after_transition on: :sell do |listing|
      listing.features.clear
      listing.add_to_seller_recent_cache
      Listings::AfterSaleJob.enqueue(listing.id)
    end

    before_transition on: :relist do |listing|
      listing.sold_at = nil
      listing.activated_at = Time.now
    end
    event :relist do
      transition :sold => :active
    end
    after_transition on: :relist do |listing|
      listing.features.clear
      listing.add_to_seller_recent_cache
      Listings::AfterRelistJob.enqueue(listing.id)
    end

    [:inactive, :active, :sold].each do |s|
      state s do
        # title validated by Sluggable
        validates :description, :presence => true
        validates :price, :presence => true, :allow_blank => true,
          :numericality => {:greater_than_or_equal_to => MINIMUM_PRICE,
                            :minimum_price => ActionController::Base.helpers.number_to_currency(MINIMUM_PRICE)}
        validates :shipping, :allow_blank => true,
          :numericality => {:greater_than_or_equal_to => 0.00,
                            :minimum_price => ActionController::Base.helpers.number_to_currency(0.00)}
        validates :tax, :allow_blank => true,
          :numericality => {:greater_than_or_equal_to => 0.00,
                            :minimum_price => ActionController::Base.helpers.number_to_currency(0.00)}
        validates :category_id, :presence => true
        # custom validators don't seem to work here, so validate photos this way
        validates_with HasPhotosValidator, SellerStateValidator, DimensionsValidator, SizeValidator,
                       ShippingOptionValidator, GreaterThanPriceValidator
      end
    end
  end

  def visible?
    active? || sold?
  end

  def new?
    1.day.ago < self.created_at
  end

  attr_accessor :size_name, :brand_name
  attr_accessible :title, :description, :price, :original_price, :shipping, :seller_pays_marketplace_fee,
    :handling_duration, :size_name, :brand_name, :dimension_value_id, :category_id, :tag_id
  attr_accessible :title, :description, :price, :original_price, :shipping, :seller_pays_marketplace_fee,
    :handling_duration, :size_name, :brand_name, :dimension_value_id, :category_id, :tag_id, as: :admin

  scope :active, where(:state => :active)
  # this listing has been published at some point (slight assumption, because a listing can go from
  # active -> inactive, but it's good enough)
  scope :published, without_states(:incomplete, :inactive)
  scope :draft, with_states(:incomplete, :inactive)
  scope :cancellable, without_state(:sold, :cancelled)

  default_sort_column :updated_at
  default_sort_direction :desc
  search_columns :title

  after_initialize do
    begin
      self.pricing_version ||= DEFAULT_PRICING_VERSION
    rescue ActiveModel::MissingAttributeError
      # according to:
      # http://www.tatvartha.com/2011/03/activerecordmissingattributeerror-missing-attribute-a-bug-or-a-features/
      # this should only happen on Model.exists?() call. It can be safely ignored.
    end
  end

  before_save do
    # Creates an item if one hasn't been assigned.
    self.item ||= Item.create!
  end

  before_validation do
    if self.dimension_values
      self.dimension_values = self.dimension_values.select {|v| self.valid_dimension_values.include? v}
    end
  end

  def initialize(*)
    raise "Cannot directly instantiate Listing" if self.class == Listing
    super
  end

  def anchor_instance
    @anchor_instance ||= Anchor::Listing.new(listing_id: self.id)
  end

  def buyer_id
    if order and order.respond_to?(:buyer_id)
      order.buyer_id
    else
      #XXX-buyer-id remove once we roll buyer id -> order code
      read_attribute(:buyer_id)
    end
  end

  def buyer(*args)
    if order and order.respond_to?(:buyer_id)
      order.buyer(*args)
    else
      #XXX-buyer-id remove once we roll buyer id -> order code
      bid = read_attribute(:buyer_id)
      User.find(bid) if bid
    end
  end

  # Parses and rebuilds the HTML fragment structure of the description to prevent any poorly structured HTML
  # from blowing up the page.  We can do this before writing because malformed HTML will never have value to us.
  def description=(html)
    super(Nokogiri::HTML::fragment(html).to_html)
  end

  # Returns a map of dimension slug to dimension value id for the dimension values attached to the listing.
  def dimension_values_id_map
    dimension_values.includes(:dimension).inject({}) {|m, dv| m[dv.dimension.slug] = dv.id; m}
  end

  # Returns the listing's value for the specified dimension, if any.
  def dimension_value_for(dimension)
    dimension_values.detect {|d| d.dimension_id == dimension.id}
  end

  def valid_dimension_values
    self.category ? self.category.dimensions.map(&:values).flatten : []
  end

  def placeholder?
    self.title == PLACEHOLDER_TITLE
  end

  def pricing_scheme
    @pricing_scheme ||= Brooklyn::PricingScheme.for_version(pricing_version)
  end

  delegate :buyer_fee_fixed, :buyer_fee_variable, :seller_fee_fixed, :seller_fee_variable, :to => :pricing_scheme

  # the fee that we nominally charge to the buyer for the privilege of transacting in our marketplace. calculated based
  # on +subtotal+ (price + shipping).
  def marketplace_fee
    ((subtotal * buyer_fee_variable) + buyer_fee_fixed).round(2)
  end

  # returns the actual fee charged to the buyer for the transaction. if the seller is eating the marketplace fee, then
  # returns 0. otherwise, returns +marketplace_fee+.
  def buyer_fee
    (seller_pays_marketplace_fee? ? 0 : marketplace_fee).to_d
  end

  def buyer_fee?
    buyer_fee > 0
  end

  def transaction_fee
    (subtotal * seller_fee_variable) + seller_fee_fixed
  end

  # the fee that we charge to the seller for the privilege of transacting in our marketplace. calculated based on
  # +subtotal+. also includes +marketplace_fee+ is the seller is eating that. also includes the cost of prepaid
  # shipping, if that's being used, as the seller is essentially buying that product from us.
  def seller_fee
    amount = transaction_fee
    amount += marketplace_fee if seller_pays_marketplace_fee?
    amount += prepaid_shipping if prepaid_shipping?
    amount.to_d.round(2)
  end

  def price
    read_attribute(:price) || 0.0.to_d
  end

  def original_price
    super
  rescue NameError
    nil
  end

  def shipping
    read_attribute(:shipping) || 0.0.to_d
  end

  def free_shipping
    shipping.nil? || shipping == 0
  end

  def free_shipping?
    !!free_shipping
  end

  def prepaid_shipping
    prepaid_shipping? ? shipping_option.rate : 0.0.to_d
  rescue NoMethodError # back compat
    0.0.to_d
  end

  def prepaid_shipping?
    !shipping_option.nil?
  rescue NoMethodError # back compat
    false
  end

  def shipping_option_code
    prepaid_shipping? ? shipping_option.code : nil
  rescue NoMethodError # back compat
    nil
  end

  def basic_shipping?
    not prepaid_shipping?
  end

  def buyer_pays_marketplace_fee?
    !seller_pays_marketplace_fee?
  end

  # the transaction amount (also, the basis on which +marketplace_fee+ is calculated). includes the listing price
  # and shipping price.
  def subtotal
    (price + shipping).to_d
  end

  # Returns the total price of this listing, including shipping, tax, and commissions.
  def total_price
    (subtotal + buyer_fee).to_d
  end

  def proceeds
    [subtotal - seller_fee, 0.to_d].max
  end

  # Returns whether or not the cost of the given prepaid shipping option is covered by the amount the buyer pays
  # less the transaction fee.
  def prepaid_shipping_covered?(option)
    total_price - transaction_fee >= option.rate
  end

  # Returns whether or not a given user is the buyer of this listing.
  def bought_by?(user)
    order && order.bought_by?(user)
  end

  # Returns whether or not a given user is the seller of this listing.
  def sold_by?(user)
    seller_id == user.id
  end

  # Returns whether or not this listing has any photos associated with it
  def has_photos?
    photos.count > 0
  end

  # Increments the listing's view count by one.
  def incr_views
    @anchor_instance = anchor_instance.incr_views
  end

  # Returns the listing's view count. Not guaranteed to have a value before +incr_views+ or +incr_shares+ is called.
  def views
    anchor_instance.views || 0
  end

  # Increments the listing's share count for +network+ by one.
  def incr_shares(sharer, network)
    @anchor_instance = anchor_instance.incr_shares(network)
    notify_observers(:after_share, sharer, network) if sharer
  end

  # Returns the listing's share count for +network+ (if specified) or the total share count for all networks. Not
  # guaranteed to have a value before +incr_views+ or +incr_shares+ is called.
  def shares(network = nil)
    return 0 unless anchor_instance.shares
    if network
      anchor_instance.shares[network.to_s]
    else
      anchor_instance.shares.values.sum
    end
  end

  def flag(user)
    Rails.logger.debug("Flagging listing #{self.id} for user #{user.id}")
    f = flags.new
    f.user = user
    f.save!
    f
  end

  # Returns a list of ids for users who have interest in this listing - the seller, the buyer, and their followers
  def interested_ids
    observer_ids = [seller_id]
    observer_ids << seller.follows.map(&:follower_id)
    observer_ids.flatten.compact.uniq
  end

  # Returns whether or not the listing is featured for its category.
  def featured_for_category?(force_reload = false)
    category_feature(force_reload) != nil
  end

  # Stop featuring this listing for its category.
  def unfeature_for_category
    features.delete(category_feature) if category_feature
  end

  # Returns whether or not the listing is featured for the given tag.
  def featured_for_tag?(tag, options = {})
    !tag_feature(tag, options).nil?
  end

  # Stop featuring this listing for the given tag.
  def unfeature_for_tag(tag)
    feature = tag_feature(tag)
    features.delete(feature) if feature
  end

  def tag_feature(tag, options = {})
    tag_features(options[:force_reload] == true).detect {|f| f.featurable_id == tag.id}
  end

  def on_feature_list?(feature_list, options = {})
    !feature_list_feature(feature_list, options).nil?
  end

  def unfeature_from_feature_list(feature_list)
    feature = feature_list_feature(feature_list)
    features.delete(feature) if feature
  end

  def feature_list_feature(feature_list, options = {})
    feature_list_features(options[:force_reload] == true).where(featurable_id: feature_list.id).first
  end

  # Creates and returns an order for the listed item from +buyer+.
  def initiate_order(buyer)
    raise "Listing must be active" unless active?
    create_order(buyer: buyer, :private => buyer.private?(:purchase_details))
  end

  def category_slug
    category.slug if category
  end

  def assign_attributes(params, options = {})
    params = params.dup # don't eff with the params we're given
    category_id = params.delete(:category_id)
    category_slug = params.delete(:category_slug)
    dimensions = params.delete(:dimensions)
    tags = params.delete(:tags)
    shipping_option_code = params.delete(:shipping_option_code)
    free_shipping = params.delete(:free_shipping)

    super(params, options)

    self.category = if category_id.present?
      Category.find(category_id)
    elsif category_slug.present?
      Category.find_by_slug(category_slug)
    else
      nil
    end

    # back compat - remove when prepaid is in
    self.shipping = 0 if free_shipping.present? && (free_shipping == true || free_shipping.to_s == '1')
    self.dimension_value_ids = dimensions.values if dimensions.present? && dimensions.values.all? { |v| v.to_i > 0 }
    self.assign_tag_string(tags, options) if tags.present?

    # XXX: theoretically if there is an order and it has been shipped we should not allow the shipping option to be
    # changed. however, we don't have a model-level story for keeping the listing from being changed in any way once
    # there is an order in flight. at the moment the ui does not present an edit link for listings with orders, so we're
    # kinda safe for now, but we do need to protect ourselves better at the model level.
    if shipping_option_code.present? && shipping_option_code != "on"
      so = self.shipping_option || ShippingOption.new
      so.copy_from_config!(shipping_option_code)
      self.shipping_option = so
      addr = seller && seller.default_shipping_address
      if addr && !self.return_address
        ra = self.build_return_address
        ra.copy!(addr)
        self.return_address = ra
      end
    else
      self.shipping_option = nil if self.shipping_option
    end
  end

  # don't want to override tags= which is provided by has_many :tags, but we do want to be able to set the tags
  # based on a string of tag names.
  def assign_tag_string(string, options = {})
    list = string.split(/\s*,\s*/).reject {|tag| tag.strip.empty?}
    assign_tag_names(list, options)
  end

  def tag_string
    self.tag_names.join(", ")
  end

  def tag_string=(string)
    assign_tag_string(string)
  end

  def assign_tag_names(list, options = {})
    old_tag_set = self.tags
    new_tag_set = Tag.find_or_create_all_by_name(list)
    old_tags_to_keep = old_tag_set & new_tag_set
    new_tags = new_tag_set - old_tag_set
    new_tags = reject_illegal(new_tags) unless options[:as] == :admin
    self.tags = old_tags_to_keep + new_tags
  end

  def add_tags(tags)
    self.tags += Array.wrap(tags)
  end

  def remove_tags(tags)
    self.tags -= Array.wrap(tags)
  end

  def reject_illegal(tags)
    illegal_tags = tags.select(&:internal?)
    if illegal_tags.any?
      self.warnings.add(:tags, :illegal, tags: illegal_tags.map(&:name).to_sentence, count: illegal_tags.count)
    end
    tags - illegal_tags
  end

  def tag_names
    self.tags.map(&:name)
  end

  def tag_slugs
    self.tags.map(&:slug)
  end

  def size_name
    size.name if size
  end

  def size_name=(name)
    write_attribute(:size_name, name)
    if name.present?
      tag = Tag.where(type: 's', slug: Tag.compute_slug(name)).first
      self.size = tag.present?? tag.primary : nil
    else
      self.size = nil
    end
  end

  def brand_name
    brand.name if brand
  end

  def brand_name=(name)
    self.brand = name.present?? Tag.find_or_create_by_name(name, type: 'b') : nil
  end

  def condition_dimension
    @condition_dimension ||= Dimension.find_by_category_id_and_slug(self.category_id, :condition)
  end

  def condition_dimension_value
    self.dimension_values.find_by_dimension_id(condition_dimension.id) if condition_dimension
  end

  # simple helper while we only use dimensions for one thing
  def condition=(cond)
    return unless category
    current = self.condition_dimension_value
    if cond.nil?
      self.dimension_values.delete_all
    else
      unless current && current.value.downcase == cond.downcase
        unless condition_dimension && value = condition_dimension.values.find_by_value(cond)
          raise "#{cond} is not a valid condition"
        end
        self.dimension_values = [value]
      end
    end
  end

  def condition
    condition_dimension_value.value if condition_dimension_value
  end

  def loveable?
    self.active? || self.sold?
  end

  def shareable?
    self.active? || self.sold?
  end

  def more_from_this_seller_count
    self.class.where(['id <> ?', self.id]).where(seller_id: self.seller_id).with_state(:active).count
  end

  def more_from_this_seller(options = {})
    limit = options.fetch(:limit, 3)
    logger.debug("Finding more from seller #{seller_id} of listing #{id}")
    relation = self.class.where('id <> ?', self.id).where(seller_id: self.seller_id).with_state(:active)
    relation = relation.includes(options[:includes]) if options[:includes]
    relation.limit(limit).order('created_at DESC')
  end

  # get a set of listings that are similar to this one (similar meaning theoretically of interest to someone who
  # is interested in this listing)
  # XXX: should just eagerly fetch photos, but can't because the +more_like_this+ method barfs on the +include+ option
  # probably fixable in sunspot
  def related(options = {})
    begin
      mlt = more_like_this do
        with(:state).equal_to(:active)
        # the +more_like_this+ search is purely text-based, but a $1 item is not really like a $100 item in the eyes
        # of most shoppers, so we box the pricing a bit.
        with(:price).greater_than(price * Brooklyn::Application.config.listings.more_like_this.min_price_factor)
        with(:price).less_than(price * Brooklyn::Application.config.listings.more_like_this.max_price_factor)
        # don't actually need pagination per se, but it's the mechanism to limit results
        paginate(page: 1, per_page: options.fetch(:limit, 9))
      end
      mlt.results
    rescue Exception => e
      # getting related products is not critical, so we'll just act like there aren't any if something goes bad
      logger.error("Error #{e} fetching related listings")
      []
    end
  end

  def reorder_photos_by_uuid(uuids)
    photos = self.photos.each_with_object({}) { |p,h| h[p.uuid] = p }
    ListingPhoto.transaction do
      uuids.each do |uuid|
        photo = photos.delete(uuid)
        raise "Non-existent photo ID [#{uuid}] in reorder request" unless photo
        photo.position = uuids.index(photo.uuid) + 1
        photo.save!
      end
      raise "Not all photo IDs provided in reorder request" if photos.count > 0
    end
  end

  def copy_master_return_address!(address_or_id)
    new_address = address_or_id.is_a?(PostalAddress) ? address_or_id : self.seller.postal_address(address_or_id)
    if new_address
      if not (self.return_address && self.return_address.equivalent?(new_address))
        transaction do
          self.return_address.destroy if self.return_address
          self.return_address = new_address.dup
        end
      end
    else
      logger.warn("No such postal address #{address_or_id} for seller #{self.seller.id}")
    end
  end

  def self.new_placeholder
    new(title: PLACEHOLDER_TITLE)
  end

  # override of the default Sluggable implementation
  # if this is a new listing, we don't want to iterate over thousand's of slugs looking for a unique one
  # we also don't want to expose the listing count, but if there's a duplicate on the timestamp, the regular
  # sluggable code will still look for a unique suffix
  def self.compute_slug(title)
    slug = title.to_s.parameterize
    title == PLACEHOLDER_TITLE ? "#{slug}-#{Time.now.to_i}" : slug
  end

  def self.count_sold_by(user, *states)
    scope = where(seller_id: user.id)
    if states.any?
      scope = scope.with_states(states)
    else
      scope = scope.group(:state)
    end
    scope.count
  end

  def self.count_bought_by(user)
    #XXX-buyer-id move back to buyer_id: foo syntax when we drop buyer_id from listing
    joins(:order).where(:state => :sold).where('orders.buyer_id = ?', user.id).count
  end

  # Returns a query scope for the listings in certain states where +user+ is the seller.
  def self.sold_by(user, states, options = {})
    scope = where(:state => states).where(:seller_id => user.id)
    scope = scope.includes(options[:includes]) if options[:includes]
    scope = scope.limit(options[:limit]) if options[:limit]
    sorted(scope, options[:sort] || {})
  end

  # Returns a query scope for the sold listings where +user+ is the buyer.
  def self.bought_by(user, options = {})
    #XXX-buyer-id move back to buyer_id: foo syntax when we drop buyer_id from listing
    scope = joins(:order).where(:state => :sold).where('orders.buyer_id = ?', user.id)
    scope = scope.includes(options[:includes]) if options[:includes]
    sorted(scope, options[:sort] || {})
  end

  # Returns a relation describing visible listings, optionally restricted to those identified by +ids+.
  #
  # @param [Array] ids (+nil+) constrain the query to only these listings (deprecated)
  # @option options [Array] :id constrain the query to only these listings
  # @option options [Array] :exclude_disliked_by constrain the query to only the listings not disliked by these users
  # @options option [Integer] :limit if provided, returns up to this many listings
  def self.visible(*args)
    options = args.extract_options!
    ids = args.any? ? args.shift : nil
    q = with_states(:active, :sold)
    ids = Array.wrap(ids).compact
    ids += Array.wrap(options[:id]).compact if options[:id].present?
    q = q.where(id: ids) if ids.any?
    if options[:exclude_disliked_by].present?
      dislikers = options[:exclude_disliked_by]
      disliker_ids = Array.wrap(dislikers).compact.map { |disliker| disliker.is_a?(User) ? disliker.id : disliker }
      q = q.where("#{quoted_table_name}.id NOT IN (SELECT listing_id FROM dislikes WHERE user_id IN (?))", disliker_ids)
    end
    if options[:limit].present?
      q = q.limit(options[:limit].to_i)
    end
    q
  end

  # Returns a query scope for the listings ordered by array of +ids+ passed.
  def self.order_by_ids(ids)
    order("field(id, #{ids.join(',')})") if ids.any?
  end

  def self.visible_counts(user_ids)
    scope = select('seller_id, COUNT(*) AS count').with_states(:active, :sold).where(seller_id: user_ids).
      group(:seller_id)
    scope.each_with_object({}) {|l, m| m[l.seller_id] = l.count}
  end

  # Executes the scoped query, sorting the result according to the +order+ and +direction+ options.
  def self.sorted(scope, options = {})
    # sort in memory since many of the sort options are computed based on associated objects
    # XXX: if somebody can think of a clean way to reverse the comparison for each of these comparator functions
    # so that we don't have to reverse the result array at the end of the method, let's hear it
    # XXX: use datagrid !@#$@
    comparator = case (options[:order] || '').to_sym
    when :price
      lambda { |a, b| a.price <=> b.price }
    when :shipping
      lambda { |a, b| (a.shipping || 0.00) <=> (b.shipping || 0.00) }
    when :total_price
      lambda { |a, b| a.total_price <=> b.total_price }
    when :listed
      lambda { |a, b| a.created_at <=> b.created_at }
    when :created
      lambda { |a, b| a.created_at <=> b.created_at }
    when :purchased
      scope = scope.includes(:order)
      lambda { |a, b| a.order.confirmed_at <=> b.order.confirmed_at }
    when :buyer
      scope = scope.includes(order: :buyer)
      lambda { |a, b| a.buyer.name <=> b.buyer.name }
    when :seller
      scope = scope.includes(:seller)
      lambda { |a, b| a.seller.name <=> b.seller.name }
    when :status
      scope = scope.includes(:order)
      lambda { |a, b| a.order.status <=> b.order.status }
    else
      lambda { |a, b| a.title <=> b.title }
    end
    listings = scope.all.sort(&comparator)
    if (options[:direction] || '').to_sym == :desc
      listings.reverse
    else
      listings
    end
  end

  def self.datagrid_sort(sort_param, direction_param, options = {})
    case sort_param
    when 'seller' then [['users.name', direction_param]]
    when 'category' then [['categories.name', direction_param]]
    when 'order_status' then [['orders.status', direction_param]]
    else super
    end
  end

  # Returns the most recently created active listings.
  def self.new_arrivals(options = {})
    logger.debug("Finding newly arrived listings")
    scope = with_state(:active).order("created_at DESC")
    scope = scope.where("seller_id NOT IN (?)", Array.wrap(options[:exclude_sellers])) if options[:exclude_sellers]
    scope = scope.limit(options[:limit]) if options[:limit]
    scope = scope.includes(options[:includes]) if options[:includes]
    scope.all
  end

  def self.most_popular(options = {})
    logger.debug("Finding most popular listings")
    options[:per_page] = options.delete(:limit) || 6
    options[:sort] = 'popular'
    ListingSearcher.new(options).all
  end

  # Returns a hash of stats info keyed by listing id.
  def self.stats(ids, options = {})
    if ids.any?
      logger.debug("Loading stats for listings #{ids}")
      Anchor::Listing.stats(ids, options)
    else
      {}
    end
  end

  # Overrides the Likeable method to ensure that "like visible" listings are active or sold only.
  #
  # @return [ActiveRecord::Relation]
  # @see Likeable#like_visible
  def self.like_visible(ids, options = {})
    super.with_state(:active, :sold)
  end

  # Returns those identified listings which can be displayed in a listing feed. This includes active and sold listings
  # only.
  #
  # @param [Array] ids the listings to find
  # @return [Array] the corresponding active and sold listings
  def self.find_feed_displayable(ids, options = {})
    includes = options[:includes] || {}
    where(id: ids.compact.uniq).with_states(:active, :sold).includes(includes)
  end

  def self.visible_ids_for_tag_id(tag_id, limit=0)
    select("#{quoted_table_name}.id").joins(:tag_attachments).with_states(:active, :sold).
      where(listing_tag_attachments: {tag_id: tag_id}).order(:state).limit(limit).map(&:id)
  end

  # Returns visible listings that have been recently created.
  #
  # @option options [Array] :excluded_ids specifies the ids of listings to exclude from the results
  # @option options [Array] :includes specifies associations to be eager fetched
  # @option options [Integer] :per the maximum number of listings to return
  def self.find_recently_created(options = {})
    relation = with_states(:active, :sold).
               order("#{quoted_table_name}.created_at DESC").
               page(1)
    if options[:excluded_ids]
      relation = relation.where("#{quoted_table_name}.id NOT IN (?)", Array.wrap(options[:excluded_ids]).join(','))
    end
    [:per, :includes].each do |meth|
      relation = relation.send(meth, options[meth]) if options[meth]
    end
    relation
  end

  def self.defer_solr_commits=(should_defer)
    Thread.current[:listing_no_solr_commit] = should_defer
  end

  def self.defer_solr_commits?
    !!Thread.current[:listing_no_solr_commit]
  end

  # turn off all solr commits (for listings) during the execution of this code block
  # a single commit will be performed at the end
  def self.solr_commit_at_end(&block)
    self.defer_solr_commits = true
    block.call
    self.defer_solr_commits = false
    Sunspot.commit
  end

  # override the default implementation that gets called in the rake task, so that we do it more sanely
  # and don't index non-active listings
  def self.solr_reindex(options = {})
    # not using batches for this model is insane so don't allow setting it to +nil+
    options[:batch_size] ||= 1000
    # batch commit is reckless, because it wipes the entire index before starting on rebuilding it
    options[:batch_commit] = false
    options[:includes] = [:category, :seller, :tags, :dimension_values]
    super(options)
  end

  # Returns true if listing photos are stored in S3 rather than the local filesystem.
  def self.photos_stored_remotely?
    not Brooklyn::Application.config.files.respond_to?(:local)
  end

  def self.html_helper
    @html_helper ||= Brooklyn::HTML.new
  end

  def add_uploaded_photo!(upload)
    photo = photos.build
    photo.file = upload
    photo.save!
    photo
  end

  def has_offer_from?(user)
    offers.where(user_id: user.id).any?
  end

  # Returns a relation describing the listings created by +user+ in reverse chronological order.
  #
  # @options options [Integer] +limit+
  def self.recently_listed_by(user, options = {})
    q = visible.where(seller_id: user.id).order('created_at DESC')
    q = q.limit(options[:limit]) if options[:limit]
    q
  end

  def self.recently_listed_by_ids(user, options = {})
    recently_listed_by(user, options).select(:id).map(&:id)
  end

  def add_to_seller_recent_cache
    seller.recent_listed_listing_ids << self.id unless seller.recent_listed_listing_ids.include?(seller.id)
  end

  def evict_from_seller_recent_cache
    seller.recent_listing_ids.delete(self.id)
  end

  def self.browse_new_arrivals_since
    Brooklyn::Application.config.listings.browse.new_arrivals_since
  end

  # Returns a mapping of listing ids to whether the listing is featured at all.
  def self.features_counts_for_listings(listing_ids = nil)
    ListingFeature.where(listing_id: listing_ids).count(group: :listing_id)
  end

  # Returns the most liked visible listings within a window of time.
  #
  # When any listings have been liked during the specified window, the relation which returns the listings does not
  # have any pagination information attached. Therefore the method also returns a secondary relation that includes
  # pagination methods. This relation does not return listings and should only be used for accessing pagination data.
  #
  # When no listings have been liked during the specified window, the returned relations describe the most recently
  # created visible listings. In this case, both relations return the same set of listings and include the same
  # pagination data.
  #
  # @param [Integer] window the number of days before +date+ that is the earliest time for which likes are considered
  # @option options [Integer] date (now) the epoch time that is the latest time for which likes are considered
  # @option options [Boolean] normalize (false) whether to use the normalization algorithm for decaying trending
  #   listings over time
  # @option options [Integer] page (1)
  # @option options [Integer] per
  #
  # @return [ActiveRecord::Relation, ActiveRecord::Relation] a tuple of the relation that will return the trending
  #   listings and the relation that is pimped with pagination methods
  def self.find_trending(window, options = {})
    logger.debug("Finding trending listings from the last #{window} days")
    page = options[:page] || 1
    date = options[:date] || Time.zone.now.to_i
    listing_ids = Listing.recently_liked(window, page: page, per: options[:per], normalize: options[:normalize],
                                         date: date)
    if listing_ids.any?
      relation = visible(listing_ids).order_by_ids(listing_ids)
      page_manager = listing_ids
    else
      logger.debug("No listings liked in the last #{window} days")
      relation = visible.reverse_order.page(page)
      if options[:per].present?
        relation = relation.per(options[:per])
      end
      page_manager = relation
    end
    [relation, page_manager]
  end

  # @options options [Array] +:exclude_sellers+ +User+s or ids whose listings should not be considered
  # @see +::find_trending+
  def self.find_trending_ids(window, options = {})
    # because of the weird paging issue with ::find_trending, it's a pain in the ass to directly support
    # the exclude_sellers option there, so we'll just do it here.
    (relation, page_manager) = find_trending(window, options)
    relation = relation.select("DISTINCT #{quoted_table_name}.id")
    if options[:exclude_sellers].present?
      exclude_seller_ids = Array.wrap(options[:exclude_sellers]).compact.map { |u| u.is_a?(User) ? u.id : u }
      relation = relation.where("#{quoted_table_name}.seller_id NOT IN (?)", exclude_seller_ids)
    end
    relation.map(&:id)
  end

private

  # stop featuring the listing for its category when the category changes
  def unfeature_listing_for_category
    unfeature_for_category if category_id_changed?
  end
  before_save :unfeature_listing_for_category

  # updates the listing's category feature based on the +featured_category_toggle+ attribute (whose value is
  # interpreted to be true if it is +"1"+).
  def update_category_feature
    unless featured_category_toggle.nil?
      toggle = featured_category_toggle == true || featured_category_toggle == "1"
      features.delete(category_feature) if category_feature and not toggle
      features.create!(featurable: category) if not category_feature and toggle
    end
  end
  before_save :update_category_feature

  # updates the listing's tag features if the +featured_tag_ids+ attribute has been assigned a value (which must be an
  # array of tag id strings).
  def update_tag_features
    unless featured_tag_ids.nil?
      tag_features.each do |f|
        features.delete(f) unless featured_tag_ids.include?(f.featurable_id.to_s)
        featured_tag_ids.delete(f.featurable_id.to_s)
      end
      featured_tag_ids.each do |t|
        features.create!(featurable: Tag.find(t)) if t.present?
      end
    end
  end
  before_save :update_tag_features

  def update_feature_list_features
    unless featured_feature_list_ids.nil?
      feature_list_features.each do |f|
        features.delete(f) unless featured_feature_list_ids.include?(f.featurable_id.to_s)
        featured_feature_list_ids.delete(f.featurable_id.to_s)
      end
      featured_feature_list_ids.each do |t|
        features.create!(featurable: FeatureList.find(t)) if t.present?
      end
    end
  end
  before_save :update_feature_list_features

  # sets the +featured_at+ timestamp if there are any features and the timestamp has not yet been set.
  def set_featured_at
    just_featured = features.any? && featured_at.nil?
    self.featured_at = Time.now if just_featured
    yield
    notify_observers(:after_feature) if just_featured
  end
  around_save :set_featured_at

  # use an around callback on the save method, so we can determine what was changed and include that in a custom
  # +after_save_with_fields+ notification
  def field_save_notifier
    changed_fields = changed
    yield
    notify_observers(:after_save_with_fields, changed_fields)
  end
  around_save :field_save_notifier
end
