require 'redis/objects'
require 'rubicon/models/profile'
require 'anchor/models/user'
require 'lagunitas/models/user'
require 'pyramid/models/user'
require 'state_machine'
require 'datagrid'
require 'stats/trackable'
require 'set'

class InvalidCreditModification < Exception; end

class UnfinalizedOrdersValidator < ActiveModel::Validator
  def validate(user)
    user.errors.add(:unfinalized_orders, I18n.translate('activerecord.errors.models.user.user.orders.unfinalized')) if
      user.has_unfinalized_orders?
  end
end

class User < ActiveRecord::Base
  include Redis::Objects
  include Sluggable
  include ApiAccessable
  include Users::Authable
  include Users::Autofollowable
  include Users::Collections
  include Users::Dislikes
  include Users::Interests
  include Users::Suggestable
  include Users::WhoToFollow
  include Users::AutoShareable
  include Users::RecentListingsQueue
  include Users::KeyValueStash
  include Users::ListingAccess
  include Users::Likes
  include Users::Notifiable
  include Users::Preferences
  include Users::TopFeedListings
  include Users::InviteAcceptance
  include Users::TopMessaging
  include Users::Demographics
  include Users::Balanced
  include Users::Mixpanel
  include Users::Api
  include Users::Haves
  include Users::Wants
  include Users::PriceAlerts
  include Stats::Trackable
  include Brooklyn::ABTesting
  include Brooklyn::Email
  include Brooklyn::UniqueIndexEnforceable
  include Brooklyn::Sprayer

  cattr_accessor :password_pepper
  @@password_pepper = 'b7063e21febdb131af2fae07231663db1870e6ba4961a3e6de4f93d9620bc80a9ec563e4b172ca03d620e491d1f9703ff6c0b6557e0fbbd44fb1cb0071e2e8d2'

  cattr_accessor :password_cost
  @@password_cost = 10

  cattr_accessor :guest_user_lifetime
  @@guest_user_lifetime = 7.days

  belongs_to :person
  has_many :credits, :dependent => :destroy
  has_many :email_accounts, :dependent => :destroy
  has_many :follows, :dependent => :destroy
  has_many :followers, :through => :follows, :source => :follower
  has_many :follow_tombstones, :dependent => :destroy
  has_many :followings, :class_name => "Follow", :foreign_key => 'follower_id', :dependent => :destroy
  has_many :followees, :through => :followings, :source => :user
  has_many :following_tombstones, :class_name => 'FollowTombstone', :foreign_key => 'follower_id',
    :dependent => :destroy
  has_many :seller_listings, :class_name => 'Listing', :foreign_key => :seller_id, :dependent => :destroy
  has_many :flagged_listings, class_name: 'ListingFlag', dependent: :destroy
  has_many :buyer_orders, :class_name => 'Order', :foreign_key => :buyer_id, :dependent => :destroy
  has_many :cancelled_orders, :foreign_key => :buyer_id, :dependent => :destroy
  has_many :postal_addresses, :dependent => :destroy
  has_many :shipping_addresses, class_name: 'PostalAddress',
      conditions: {ref_type: PostalAddress::RefType::SHIPPING, order_id: nil, cancelled_order_id: nil},
      readonly: true, after_add: :default_for_shipping, after_remove: :default_for_shipping
  has_many :order_ratings, :dependent => :destroy
  has_one :api_config

  has_slug :slug, unique_suffix: true, validate_sluggable_if: lambda { connected? || registered? },
    validate_slug_if: lambda { registered? }
  has_uuid
  has_many :created_annotations, foreign_key: :creator_id
  has_many :annotations, as: :annotatable, dependent: :destroy
  has_many :user_interests, dependent: :destroy
  has_many :interests, through: :user_interests
  has_many :user_suggestions
  has_many :listing_offers, dependent: :destroy

  has_many :dislikes, dependent: :destroy
  has_many :disliked, through: :dislikes, source: :listing

  # email is validated with more restrictions when registering, but it has to at least be unique in all states, so that
  # it doesn't blow up on the unique index at the db level
  validates :email, uniqueness: true, length: {maximum: 255}, email: {allow_blank: true}

  # validations for profile settings, all of which are optional and not filled in at registration
  validates :location, length: {maximum: 255, allow_blank: true}
  validates :bio,      length: {maximum: 300, allow_blank: true}
  validates :web_site, length: {maximum: 255, allow_blank: true}, uri: {allow_blank: true}

  attr_accessor :password
  attr_accessor :current_password
  before_save :encrypt_password
  before_destroy :delete_from_services

  attr_accessor :guest_to_absorb

  attr_accessible :email, :email_confirmation, :password, :password_confirmation, :current_password, :name, :firstname,
    :lastname, :slug, :location, :bio, :web_site, :reset_password_token, :web_site_enabled, :listing_access,
    :needs_onboarding
  accepts_nested_attributes_for :postal_addresses,
    reject_if: proc { |attributes| attributes.all? { |key, value| key == 'ref_type' or key == 'state' or value.blank? }}

  mount_uploader :profile_photo, ProfilePhotoUploader

  normalize_attributes :email

  delegate :for_network, :connected_to?, :invite_suggestions, to: :person

  state_machine :state, :initial => :guest do
    # guest: a user we track via id but otherwise know nothing about
    # connected: a user who has connected an external network account but not yet registered
    # registered: a user who has chosen a password
    # inactive: user has caused his account to be deactivated

    before_transition on: :connect do |user|
      user.connected_at = Time.zone.now
      user.nameify if user.name.blank?
    end
    event :connect do
      transition guest: :connected
    end
    after_transition on: :connect do |user|
      Users::AfterConnectionJob.enqueue(user.id)
    end

    state :connected do
      validates :firstname, presence: true, length: {maximum: 64}
      # name is also validated in this state - see has_slug above
    end

    before_transition on: :register do |user|
      user.registered_at = Time.zone.now
      user.slugify if user.slug.blank?
      user.validate_completely!
    end
    event :register do
      transition connected: :registered
    end
    after_transition on: :register do |user|
      user.set_just_registered
      send_welcome_emails = ! (user.guest_to_absorb.present? && user.guest_to_absorb.seller_listings.any?)
      user.absorb_guest_if_necessary
      user.create_default_collections!
      Users::AfterRegistrationJob.enqueue(user.id, send_welcome_emails: send_welcome_emails)
    end

    state :registered do
      validates :email, presence: true, uniqueness: true, length: {maximum: 255}, email: {allow_blank: true},
        confirmation: true
      validates :firstname, presence: true, length: {maximum: 64}
      validates :lastname, length: {maximum: 64}
      validates :password, presence: true, confirmation: true, :if => :should_validate_password?
      # name and slug are also validated in this state - see has_slug above
    end

    state :inactive do
      validates_with UnfinalizedOrdersValidator
    end
    event :deactivate do
      transition :registered => :inactive
    end
    before_transition on: :deactivate do |user|
      user.seller_listings.each do |listing|
        if listing.incomplete?
          listing.destroy
        elsif listing.can_cancel?
          listing.cancel!
        end
      end

      (user.follows + user.followings).each { |f| f.destroy }
    end
    after_transition on: :deactivate do |user|
      user.recent_listing_ids.clear
      user.recent_listed_listing_ids.clear
      user.recent_saved_listing_ids.clear
    end

    event :reactivate do
      transition inactive: :registered
    end
  end

  def complete_onboarding!
    notify_observers(:after_onboarding)
    Users::AfterOnboardingJob.enqueue(self.id)
  end

  # XXX: check the use cases for these scopes
  scope :registered, with_state(:registered)
  scope :unregistered, without_state(:registered)
  scope :new_this_month, where('MONTH(registered_at) = MONTH(NOW())').where('YEAR(registered_at) = YEAR(NOW())')
  scope :new_today, new_this_month.where('DAY(registered_at) = DAY(NOW())')

  # these only happen on updates where the password is changed when the user profile is updated
  validates :current_password, presence: true, on: :update, :if => :updating_password?
  validate :current_password_authenticates, on: :update, :if => :updating_password?

  default_sort_column :email
  search_columns :name, :email

  def delete_from_services
    begin
      unless guest?
        Anchor::User.destroy!(id)
        Lagunitas::User.destroy!(id)
        Pyramid::User.destroy!(id)
        Profile.find_all_for_person!(person_id).each { |p| p.unregister! }
      end
      true
    rescue Exception => e
      logger.error("exception deleting user #{id} (#{name}): #{e}")
      # don't need to do any handling because the clients do all that work, so just return false to trigger a rollback
      false
    end
  end

  def buyer_listings
    #XXX-buyer-id move back to buyer_id: foo syntax when we drop buyer_id from listing
    Listing.joins(:order).where('orders.buyer_id = ?', id)
  end

  def seller_listing_ids
    seller_listings.select(:id).map(&:id)
  end

  def display_name
    self.name || self.fb_name
  end

  def set_profile_photo_from_network(network)
    self.profile_photo.download_from_network!(network)
  end

  def async_set_profile_photo_from_network
    # grab the first network profile we can find and use it to sync.
    # this works for now because this is usually called in an after_connect
    # hook, and there should only be one network profile at this point.
    if person.network_profiles.any?
      Users::SyncPhotoJob.enqueue(id, person.network_profiles.keys.first.to_sym)
    else
      logger.warn("Can't enqueue profile photo job for person #{person.id} with no network profiles")
    end
  end

  def async_set_location_from_network
    FillLocation.enqueue(id)
  end

  # Sets the +encrypted_password+ persistent attribute if the +password+ transient attribute has a value.
  def encrypt_password
    if password.present?
      options = {}
      # BCrypt requires cost to be > 0 if specified
      options[:cost] = password_cost && password_cost > 0 ? password_cost : 1
      self.encrypted_password = BCrypt::Password.create(pepper_input_password(password), options).to_s
    end
  end

  # Updates the person's attributes using a network profile
  def update_from_profile(profile)
    raise ArgumentError, 'No profile' unless profile
    self.name = profile.name
    self.firstname = profile.first_name
    self.lastname = profile.last_name
    self.email = profile.email
    self
  end

  def nameify
    self.name = "#{self.firstname} #{self.lastname}"
  end

  def set_just_registered
    @just_registered = true
  end

  def just_registered?
    !!@just_registered
  end

  def registered_since?(datetime)
    registered? && registered_at >= datetime
  end

  def validate_completely!
    @validate_completely = true
  end

  def validate_completely?
    !!@validate_completely
  end

  def should_validate_password?
    # the only time a password can change is when the user is connected and registering or when the user is registered
    # (in the former case, registered? is still true and the state attribute is dirty)
    return false unless registered?

    # only validate password if the client explicitly signals that password validation is required
    return false unless validate_completely?

    # otherwise, just check if the user is trying to change either the password, its confirmation, or the current
    # password.
    #
    # Use nil? instead of blank? -> when a form submits an empty value, it uses "". We want to validate empty values,
    # but not unset values.
    return !password.nil? && !password_confirmation.nil?
  end

  # Used to determine when to validate the +current_password+ - ie, only when the user is registered, is not resetting
  # password, and is attempting to change the one it already has.
  def updating_password?
    registered? && !state_changed? && reset_password_token.blank? &&
      !(password.nil? && password_confirmation.nil? && current_password.nil?)
  end

  # Don't slugify before validating - we slugify explicitly when registering
  def should_slugify_before_validating?
    false
  end

  # Creates a user and transitions it to the registered state, performing validations, enqueuing post-transition jobs,
  # etc.
  #
  # If creating the user in its initial state or transitioning it to the registered state fails, rolls the entire
  # thing back and returns the unsaved user with errors.
  #
  # @return [User]
  def self.create_registered_user(params)
    person = Person.new
    user = person.build_user(params)
    transaction do
      person.save or raise ActiveRecord::Rollback
      user.connect or raise ActiveRecord::Rollback
      # an after connection job has been queued, but that's okay if transitioning to registered fails, because the
      # user record won't be found and the job just won't do anything
      user.register or raise ActiveRecord::Rollback
    end
    user
  end

  # Generates a random, unique token that can be used as a visitor id for a user.
  def self.generate_visitor_id
    SecureRandom.uuid
  end

  # helper method for vanity, so we can use a user as a "vanity context"
  def vanity_identity
    visitor_id
  end

  # Wraps ABTesting method
  def variant_for_experiment(experiment_name)
    self.class.variant_for_experiment(self.visitor_id, experiment_name)
  end

  # Creates a follow relationship between this user and +other+.
  #
  # @raise [Exception] if +other+ is not in the registered state
  # @raise [ActiveRecord::RecordNotSaved] if the follow cannot be created
  # TODO: have different variants of follow! e.g. organic_follow!(suggested_user)
  def follow!(other, options = {})
    raise "Can't follow unregistered user" unless other.registered?
    options[:follow_type] = OrganicFollow if options[:follow_type].nil?
    unless self.following?(other) or other.blocking?(self)
      logger.debug("User #{id} following user #{other.id}")
      attrs = options.fetch(:attrs, {}).reverse_merge(
        user: other,
        follower: self,
        follow_type: Follow.follow_type_id(options[:follow_type])
      )
      Follow.create!(attrs)
    end
  end

  # unset this User as a follower of +other+
  def unfollow!(other, options = {})
    # unique db index guarantees we'll only have one record at most
    follow = followings.where(user_id: other.id).first
    if follow
      logger.debug("User #{id} unfollowing user #{other.id}")
      follow.destroy
    end
    follow
  end

  def follow_all!(others)
    followed_ids = Set.new(Follow.where(:follower_id => id).map(&:user_id))

    others.each do |other|
      follow!(other, follow_type: FollowAll) if (other && self.id != other.id && !followed_ids.member?(other.id))
    end
  end

  # block another user from following
  def block!(other)
    unless self.blocking?(other)
      logger.debug("User #{id} blocking user #{other.id}")
      track_usage(:block_user, user: self)
      Block.create!(:user => other, :blocker => self)
      other.unfollow!(self)
    end
  end

  # unblock another user from following
  def unblock!(other)
    logger.debug("User #{id} unblocking user #{other.id}")
    track_usage(:unblock_user, user: self)
    Block.destroy_all(:user_id => other.id, :blocker_id => self.id)
  end

  # Returns an array of registered users who follow this user in at least one external network. No user appears more
  # than once in the array.
  def all_registered_network_followers
    follower_ids = map_connected_profiles {|profile| profile.followers.map(&:person_id)}
    self.class.where(person_id: follower_ids).with_state(:registered).all
  end

  def follow_registered_network_followers!(profile)
    follow_all!(self.class.network_followers(profile, registered_only: true).map {|a| a[0]})
  end

  def follow_inviters!(profile)
    inviter_profiles = Invite.find_inviters_of_profile_uuid(profile.id)
    inviters = self.class.where(person_id: inviter_profiles.map(&:person_id))
    follow_all!(inviters)
  end

  def follow_of(other)
    Follow.where(user_id: other.id, follower_id: id).first
  end

  # @option options [Boolean] :refollow (true) whether or not to count a refollow as a follow
  def following?(other, options = {})
    f = follow_of(other)
    return false unless f
    return false if !options.fetch(:refollow, true) && f.refollow?
    true
  end

  def blocking?(other)
    Block.where(user_id: other.id).where(blocker_id: id).exists?
  end

  # Returns a random selection of followers.
  def random_followers(limit = 5)
    followers.order('rand()').limit(limit)
  end

  # Returns a random selection of followees.
  def random_followees(limit = 5)
    followees.order('rand()').limit(limit)
  end

  def interest_followings
    InterestFollow.where(follower_id: id)
  end

  def interest_based_followees
    interest_followings.includes(:user).map{|i| i.user}
  end

  def autofollowings
    AutomaticFollow.where(follower_id: id)
  end

  def autofollow_based_followees
    autofollowings.includes(:user).map{|i| i.user}
  end

  def organic_based_followees
    OrganicFollow.where(follower_id: id).includes(:user).map{|i| i.user}
  end

  def follow_all_based_followees
    FollowAll.where(follower_id: id).includes(:user).map{|i| i.user}
  end

  def registered_follow_scope(scope, options)
    # NB: we don't actually filter on registered state (we used to), because follows should only
    # exist between registered users and that particular where clause prevents efficient use of
    # indexes in production, leading to timeouts and filled disks.
    scope = scope.page(options.fetch(:page, 0))
    scope = scope.per(options[:per]) if options[:per]
    scope = case options[:order]
            when :reverse_chron then scope.order("#{Follow.quoted_table_name}.created_at DESC")
            else scope
            end
    scope
  end

  def registered_followers(options = {})
    registered_follow_scope(followers, options)
  end

  def registered_followees(options = {})
    registered_follow_scope(followees, options)
  end

  def registered_follows(options = {})
    registered_follow_scope(follows, options)
  end

  def registered_followings(options = {})
    registered_follow_scope(followings, options)
  end

  def following_follows_for(user_ids)
    Follow.where(follower_id: self.id).where(user_id: user_ids)
  end

  # return users who are interested in the activities of this user
  def interested_users
    # ensure we always have the latest follower list (mostly affects specs, but shouldn't be horrible for perf)
    [self] + self.followers(true)
  end

  # @param [Hash] options
  # @option with_prefs [Boolean] Whether preferences should be fetched and yielded for each user.  Default is false.
  # @option batch_size [Integer] Batch size used for mysql find and preference load.  Default is 100.
  def each_interested_user(options = {}, &block)
    batch_size = options.fetch(:batch_size, 100)
    0.upto(Float::INFINITY) do |i|
      batch = followers.order("#{Follow.quoted_table_name}.follower_id").offset(i * batch_size).limit(batch_size).to_a
      break if batch.empty?
      if options[:with_prefs]
        prefs = self.class.preferences(batch)
        raise "Failed to fetch preferences for users" unless prefs.size == batch.size
        batch.each { |u| yield u, prefs[u.id] }
      else
        batch.each { |u| yield u }
      end
    end
  end

  # @option options [Hash] :tracking ({}) a map of parameters to attach to the generated tracking event
  def add_interest_in!(interest, options = {})
    ui = user_interests.where(interest_id: interest.id).first
    unless ui
      ui = user_interests.build(interest_id: interest.id)
      ui.save!
      params = options.fetch(:tracking, {}).merge(user: self, interest_name: interest.name)
      track_usage(:add_interest, params)
    end
    ui
  end

  def remove_interest_in(interest)
    UserInterest.destroy_all({interest_id: interest.id, user_id: self.id})
  end

  # Returns the interests shared with another user.
  #
  # @param [User] other a user to find shared interests for
  def find_shared_interests(other)
    # considered a single query with INTERSECT but couldn't figure out how to do it with AR and Arel and didn't
    # think it was worth constructing the query manually. am happy to revisit this choice.
    interests & other.interests
  end

  # Returns a randomly selected interest shared with another user.
  #
  # @param [User] other a user to find a shared interest for
  # @see +#find_shared_interests+
  def find_random_shared_interest(other)
    interests = find_shared_interests(other)
    interests.sample(1).first if interests.any?
  end

  # Returns the interests shared with other users.
  #
  # @param [Array] others the users to find shared interests for
  # @return [Hash] mapping user id to shared interest
  def find_random_shared_interests(others)
    other_ids = Array.wrap(others).map(&:id)
    # just formulating this query inline since it's trivial and UserInterest is just a join model anyway. if the
    # query was needed outside the model layer I'd go to the effort.
    UserInterest.includes(:interest).where(user_id: other_ids).group_by(&:user_id).
      each_with_object({}) do |(other_id, user_interests), m|
        other_interests = user_interests.map(&:interest)
        shared_interests = interests & other_interests
        m[other_id] = shared_interests.sample(1).first if shared_interests.any?
      end
  end

  # Returns the ids of the registered users who are interested in the activities of this user (including this user
  # himself).
  #
  # @return [Array]
  def interested_user_ids
    [self.id] + followers.select("#{User.quoted_table_name}.id").with_state(:registered).map(&:id)
  end

  # Returns a scope describing the active registered users whose activities this user is interested in (ie this user's
  # network).
  def interesting_users
    followees.with_state(:registered)
  end

  # Returns the ids only for this user's interesting users.
  def interesting_user_ids
    interesting_users.select("#{User.quoted_table_name}.id").map(&:id)
  end

  # Generates and saves a reset password token if necessary.
  def generate_reset_password_token!
    update_attribute(:reset_password_token, self.class.reset_password_token) if reset_password_token.blank?
  end

  # Updates the password, saving the record and clearing the token. Returns true if the passwords are valid and the
  # record was saved, false otherwise.
  def reset_password!(password, confirmation)
    self.password = password
    self.password_confirmation = confirmation
    validate_completely!
    transaction do
      if save
        self.password = nil
        self.password_confirmation = nil
        self.update_attribute(:reset_password_token, nil)
        true
      else
        false
      end
    end
  end

  # XXX: potential optimization - make each of these as has_many association and add a counter cache to the
  # corresponding belongs_to association on User

  # Returns this user's postal address with the given id. Raises +ActiveRecord::RecordNotFound+ if the identified
  # address does not exist or if it isn't associated with this user.
  def postal_address(aid)
    a = postal_addresses.where(:id => aid).first
    raise ActiveRecord::RecordNotFound, "PostalAddress #{aid} for user #{id}" unless a
    a
  end

  def listings_for_sale
    Listing.sold_by(self, :active)
  end

  def listings_for_sale_count
    Listing.count_sold_by(self, :active)
  end

  def visible_listings(options = {})
    Listing.sold_by(self, [:active, :sold], options)
  end

  def visible_listings_count
    Listing.count_sold_by(self, :active, :sold)
  end

  def listings_sold
    Listing.sold_by(self)
  end

  def listings_bought
    Listing.bought_by(self)
  end

  def completed_bought_orders_count
    self.bought_orders.where(status: :complete).count
  end

  def completed_sold_orders_count
    self.sold_orders.where(status: :complete).count
  end

  # return a count of listings this user has activated at some point
  def has_ever_activated_a_listing?
    self.seller_listings.where(has_been_activated: true).count > 0
  end

  def listings_and_loves(limit = 4)
    (visible_listings({limit: limit}) + liked).slice(0..(limit-1))
  end

  def authenticates?(password)
    if encrypted_password
      bcrypt = BCrypt::Password.new(encrypted_password)
      hashed = BCrypt::Engine.hash_secret(pepper_input_password(password), bcrypt.salt)
      hashed == encrypted_password ? self : nil
    else
      nil
    end
  end

  def pepper_input_password(password)
    password + password_pepper.to_s
  end
  private :pepper_input_password

  # Validation method called when updating the user's password
  def current_password_authenticates
    return if authenticates?(current_password) || current_password.blank?
    errors[:current_password] << I18n.t("en.activerecord.errors.models.user.attributes.not_current",
      default: "You must enter your current password.")
  end
  private :current_password_authenticates

  # Stores the remember if one needs to be generated and saves the user without validations.
  def remember_me!
    self.remember_created_at = Time.now.utc if generate_remember_timestamp?
    save(:validate => false)
  end

  # Unsets the remember and saves the user without validation.
  def forget_me!
    self.remember_created_at = nil
    save(:validate => false)
  end

  # Returns true if the remember has expired.
  def generate_remember_timestamp?
    remember_expired?
  end

  # Returns true if the remember exists but has not yet expired.
  def remember_exists_and_not_expired?
    remember_created_at && !remember_expired?
  end

  # Returns true if the remember does not exist or if the expiration time is earlier than now.
  def remember_expired?
    remember_created_at.nil? || (remember_expires_at <= Time.now.utc)
  end

  # Returns the expiration time of the stored remember (the remember timestamp plus +Brooklyn::Application.config.session.remember_for+).
  def remember_expires_at
    remember_created_at + Brooklyn::Application.config.session.remember_for
  end

  # Takes over the guest user's seller listings and destroys the guest user.
  def absorb_guest!(guest)
    raise "only registered users can absorb guests" unless registered?
    raise ArgumentError, "can only absorb guest users" unless guest.guest?
    logger.debug("User #{self.id} absorbing guest user #{guest.id}")
    transaction do
      guest.seller_listings.each do |listing|
        listing.seller = self
        listing.save!(validate: false)
      end
      guest.seller_listings.reload # clears out the listings so they don't get destroyed with the guest
      guest.destroy
    end
  end

  def absorb_guest_if_necessary
    absorb_guest!(guest_to_absorb) if guest_to_absorb
  end

  def orders
    Order.find_for_user(id)
  end

  def bought_orders
    Order.bought_by_user(id)
  end

  def has_purchased?
    bought_orders.size > 0
  end

  def sold_orders
    Order.sold_by_user(id)
  end

  def completed_bought_orders
    bought_orders.with_status(:complete)
  end

  def unfinalized_orders
    orders.reject { |o| o.finalized? }
  end

  def has_unfinalized_orders?
    unfinalized_orders.any?
  end

  def published_listing_count
    self.seller_listings.published.count
  end

  def draft_listings
    seller_listings.draft
  end

  def publish_signup!
    PublishSignup.enqueue_at(Brooklyn::Application.config.networks.publish_signup_delay_secs.second.from_now, self.id)
  end

  def share_follow!(followee, network, followee_url)
    raise ArgumentError, "user #{self.id} not following #{followee.id}" unless following?(followee)
    track_usage(:share_follow_user, user: self)
    person.share_user_followed(network, followee, followee_url)
  end

  def total_credit_value
    credits.map(&:amount).sum
  end

  # @param [Hash] options
  # @option options [Listing] listing If provided, determines if there is credit available that can be applied to
  # purchasing that listing.  Typically limited by offers tied to sellers.  Will also include credit already applied
  # to a pending order for that listing.
  def has_available_credit?(options = {})
    credit_balance(options) > 0
  end

  def earned_invitee_credit?
    @earned_invitee_credit ||= Lagunitas::CreditTrigger.find_for_user(self.id).any? do |trigger|
      trigger.is_a?(Lagunitas::InviteeCreditTrigger)
    end
  end

  def credit_balance(options = {})
    credits.available(self, options).map {|c| c.amount_remaining(options)}.sum
  end

  def credit_triggers
    Lagunitas::CreditTrigger.find_for_user(self.id)
  end

  def triggers_by_id
    credit_triggers.each_with_object({}) {|t, a| a[t.id] = t}
  end

  # convert a user to a minimal hash of attributes that can be losslessly serialized as a background job argument
  def to_job_hash
    [:id, :slug, :name, :email, :firstname].inject({}) {|m, a| m.merge!(a => send(a))}
  end

  def formatted_email
    format_email(email, name)
  end

  def sorted_shipping_addresses
    # Sort the shipping addresses so that the default one comes first if one exists;
    # the rest are sorted in name order.
    self.shipping_addresses.order('default_address DESC', :name)
  end

  def default_shipping_address
    self.shipping_addresses.where('default_address = ?', true).first
  end

  def facebook_og_post(url, action)
    self.class.facebook_og_post_user(self, url, action)
  end

  # Given a set of user ids, return a subset of the identified users
  # who are considered "closest". Currently just returns followees in
  # no particular order, but should eventually consider social network
  # information - perhaps from redhook?
  def closest_friends_among(ids, options = {})
    scope = followees.where(id: ids)
    scope = scope.limit(options[:limit]) if options[:limit]
    scope
  end

  # Returns the user's listings with orders that have completed but not yet settled.
  #
  # @return [Array]
  def listings_with_orders_awaiting_settlement
    Listing.sold_by(self, :sold, includes: :order).find_all { |l| l.order.complete? }
  end

  # Returns the total amount of order proceeds waiting to be deposited into the user's deposit account.
  #
  # @return [BigDecimal]
  def proceeds_awaiting_settlement
    listings_with_orders_awaiting_settlement.inject(0) { |m, l| l.proceeds }
  end

  # Settles all of the user's orders that have completed but not yet settled.
  #
  # @raise [Order::IncompleteSettlement] if some orders were not settled for some reason
  def settle_all_complete_orders!
    unsettled = []
    listings_with_orders_awaiting_settlement.each do |listing|
      begin
        listing.order.settle!
      rescue Exception => e
        unsettled << e
      end
    end
    raise Order::IncompleteSettlement.new(unsettled) if unsettled.any?
  end

  # Returns whether or not this user has flagged +listing+.
  #
  # @return [Boolean]
  def flagged?(listing)
    flagged_listings.where(listing_id: listing.id).any?
  end

  # Chooses listings representing this user's tastes and personality and returns information about them.
  #
  # The method is hardcoded to use the recent listings queue policy, but it can be extended to allow a policy to be
  # specified if necessary.
  #
  # The returned objects have the following attributes:
  #
  # * +listing+ - the listings themselves
  # * +photo+ - the primary photos for the listing
  #
  # @param [Hash] options options to be passed on to the policy that chooses the listings
  # @return [Array] list of info structs
  # @see Users::RecentListingsQueuePolicy
  def representative_listing_infos(options = {})
    policy = Users::RecentListingsQueuePolicy.new(options)
    policy.choose!([self])
    policy.listings_for_user(id).map do |listing|
      OpenStruct.new(listing: listing, photo: policy.photo_for_listing(listing.id))
    end
  end

  # Causes follows to be scheduled at the specified time for each user specified by +User.scheduled_follows+.
  def schedule_follows
    self.class.scheduled_follows.each do |(slug, delay)|
      Users::ScheduledFollowJob.enqueue_at(delay.from_now, id, slug)
    end
  end

  def self.formatted_mailable_addresses(addresses)
    emails = addresses.to_set
    User.select([:name, :email, :state]).where(email: addresses).each do |user|
      emails.delete(user.email)
      emails.add(user.formatted_email) unless user.inactive?
    end
    emails.to_a
  end

  # Returns the +User+ with email address matching +email+, if +password+ (after encryption) matches the
  # value of the +encrypted_password+ attribute.
  def self.authenticate(email, password)
    user = find_by_email(email)
    user && user.registered? && user.authenticates?(password)
  end

  def self.find_expired_guests
    expiration = Time.zone.now - guest_user_lifetime
    where(:state => :guest).where("created_at < ?", expiration).all
  end

  def self.find_registered_users(options = {})
    relation = with_state(:registered)
    if options[:id]
      relation = relation.where(id: options[:id])
    end
    relation
  end

  # Finds +Person+ ids for a +Network+ in batches as determined by options; similar
  # to +ActiveRecord::Batches.find_in_batches+.
  # @option options [Integer] :batch_size size of individual batched page returned
  def self.find_registered_person_ids_in_batches(options = {}, &block)
    User.where(state: :registered).select(["person_id", "id"]).
      find_in_batches(batch_size: options[:batch_size] || 100) { |batch| yield batch.map(&:person_id) }
  end

  # Returns person ids for the most recently registered users in batches. Ids are ordered reverse chronologically
  # by users' registration timestamps.
  #
  # Implementation heavily guided by +ActiveRcord::Batches::find_in_batches+ but differs in these ways:
  #
  # 1. Records are ordered by +:registered_at DESC+
  # 2. A limit to the total number of records returned can be set
  #
  # @option options [Integer] :batch_size (100) number of ids returned in each batch (may be smaller for the final batch
  #                           if +:limit+ is provided)
  # @option options [Integer] :limit the total number of ids to be returned across all batches (defaults to all ids)
  def self.find_most_recent_registered_person_ids_in_batches(options = {}, &block)
    overall_limit = options[:limit].to_i if options[:limit].present?
    batch_size = options.fetch(:batch_size, 100).to_i
    if overall_limit.present?
      batch_size = overall_limit if overall_limit < batch_size
    end
    relation = User.with_state(:registered).
                    select([:registered_at, :person_id]).
                    order('registered_at DESC').
                    limit(batch_size)
    records = relation.to_a
    total_size = 0
    while records.any?
      records_size = records.size
      total_size += records_size
      offset = records.last.registered_at
      yield records.map(&:person_id)
      break if records_size < batch_size
      if overall_limit.present?
        batch_size = overall_limit - total_size if total_size + batch_size > overall_limit
        break if batch_size == 0
      end
      # XXX: this will miss any records whose registration timestamps are equal to offset that weren't caught
      # in the previous batch. I don't see any way around this other than 1) using <= instead, 2) remembering all of
      # the ids from the previous batch, and 3) adding a NOT IN clause for those ids. worth it? doesn't seem so.
      records = relation.where("registered_at < ?", offset).limit(batch_size).to_a
    end
  end

  # Sends reset password instructions to the user with the given email address. If no such user is found, returns
  # a new instance with an error.
  def self.generate_reset_password_token(email)
    user = find_by_email(email) || User.new(email: email)
    if user.persisted? and user.registered?
      user.generate_reset_password_token!
    else
      if email.present?
        user.errors.add(:email, :not_found)
      else
        user.errors.add(:email, :blank)
      end
    end
    user
  end

  # Generates and returns a random string that can be used as a token, ensuring that the generated string is not
  # already in use as a token of the given type.
  def self.generate_token(column)
    loop do
      token = SecureRandom.base64(15).tr('+/=', 'xyz')
      break token unless where(column => token).count > 0
    end
  end

  # Generates and returns a new reset password token that is not already in use.
  def self.reset_password_token
    generate_token(:reset_password_token)
  end

  # Resets the password for the user with the given token. If no such user is found, returns a new instance with an
  # error.
  def self.reset_password_by_token(token, attributes)
    user = find_by_reset_password_token(token) || User.new(:reset_password_token => token)
    if user.persisted?
      user.reset_password!(attributes[:password], attributes[:password_confirmation])
    else
      user.errors.add(:reset_password_token, :invalid)
    end
    user
  end

  # Creates a guest user based on either the provided person or a new one.
  def self.create_guest!(person = nil)
    transaction do
      logger.debug("Creating guest user")
      person ||= Person.create!
      user = person.build_user
      user.save!
      user
    end
  end

  def self.registered_before(date)
    self.registered.where('registered_at < ?', date)
  end

  def self.count_by_state
    count(:all, select: :state, group: :state)
  end

  # get a hash of registered users by dates, including 0's when there are none
  # XXX: if we had a reporting db, this method would disappear
  def self.registrations_by_day(days)
    now = Time.now.utc
    counts = days.downto(0).inject({}) { |hash,i| hash[(now - i.days).to_date] = 0; hash }
    dbcounts = connection.execute("SELECT DATE(registered_at) AS day, COUNT(*) FROM users
      WHERE registered_at > '#{(now - days.days).to_date}' GROUP BY day ORDER BY day")
      .inject({}) { |hash,row| hash[row[0]] = row[1]; hash }
    counts.merge(dbcounts)
  end

  # Returns the identified users ordered by 1) whether or not this user follows them and 2) their own follower
  # counts. Excludes non-registered users.
  def find_ordered_by_following_and_followers(other_ids)
    sql = <<-SQL
      SELECT users.*,
             (SELECT SUM(IF(follows.follower_id = ?, 1, 0))
                     FROM follows WHERE follows.user_id = users.id) AS followed_count,
             COUNT(follows.user_id) AS followers_count
      FROM users LEFT JOIN follows ON users.id = follows.user_id
      WHERE users.id IN (?) AND users.state = 'registered'
      GROUP BY users.id
      ORDER BY followed_count DESC, followers_count DESC
    SQL
    self.class.find_by_sql([sql, self.id, other_ids])
  end

  def suggested_users
    # odd-ball looking query: The temp table is only way you can get the random ordering within each set before
    # creating the union.
    sql = interests.map do |i|
      "SELECT * FROM (SELECT `users`.* FROM `users`
       INNER JOIN
         `user_suggestions` ON `user_suggestions`.`user_id` = `users`.`id`
       WHERE
         `user_suggestions`.`interest_id` = #{i.id}
       ORDER BY RAND()
       LIMIT #{Brooklyn::Application.config.interests.cards.suggested_person_count}) as tbl#{i.id.abs}
      "
    end
    sql.any?? User.find_by_sql(sql.join(" UNION ")) : []
  end

  def followers_by_prefix(prefix, options = {})
    limit = options[:limit]
    fields = options[:fields]
    # the actual semantic of the query is "all users following this one", hence +:followings+
    scope = self.class.joins(:followings).where(follows: {user_id: self.id}).where('name LIKE ?', "#{prefix}%")
    scope = scope.limit(limit) if limit
    scope = scope.select(fields.map { |f| "#{self.class.quoted_table_name}.#{f}" }.join(', ')) if fields
    scope
  end

  # Returns the identified users ordered by their follower counts. Excludes non-registered users.
  def self.find_ordered_by_followers(other_ids)
    sql = <<-SQL
      SELECT users.*, COUNT(follows.user_id) AS followers_count
      FROM users LEFT JOIN follows ON users.id = follows.user_id
      WHERE users.id IN (?) AND users.state = 'registered'
      GROUP BY users.id
      ORDER BY followers_count DESC
    SQL
    find_by_sql([sql, other_ids])
  end

  # Returns the users and profiles associated with the network followers of the given profile. The return value is
  # an array of [user, profile] arrays representing each follower's profile and user. Recognizes the following options:
  #
  # * +registered_only+: when true, includes only those followers who are fully-registered (default false)
  # * +limit+: when provided, limits the number of results
  def self.network_followers(profile, options = {})
    followers = profile.followers
    follower_idx = followers.inject({}) {|m, p| m.merge(p.person_id => p)}

    scope = where(person_id: followers.map(&:person_id))
    scope = scope.with_state(:registered) if options[:registered_only]
    scope = scope.limit(options[:limit]) if options[:limit]
    users = scope.all

    users.map {|u| [u, follower_idx[u.person_id]]}
  end

  def self.find_for_person(person_id)
    where(person_id: person_id).includes(:person).first
  end

  def self.with_people(ids, *states)
    scope = where(id: ids.to_a)
    scope = scope.with_states(states) if states.any?
    scope.includes(:person)
  end

  def self.with_person(id)
    with_people([id]).first
  end

  # Returns only those ids from the input set that identify users in the provided states. For example, if the state
  # +:registered+ is provided, only those ids identifying registered users will be returned.
  #
  # @param [Array] ids the input ids
  # @param [Array] states the states for whose
  def self.ids_of_users_in_states(ids, *states)
    ids = ids.to_a
    if ids.any?
      if states.any?
        select(:id).where(id: ids.compact.uniq).with_states(states).map(&:id)
      else
        ids
      end
    else
      []
    end
  end

  # Returns true if profile photos are stored in S3 rather than the local filesystem.
  def self.photos_stored_remotely?
    not Brooklyn::Application.config.files.respond_to?(:local)
  end

  def self.registered_follower_counts(user_ids)
    sql = ['SELECT user_id, COUNT(*) AS follower_count FROM follows WHERE user_id IN (?) GROUP BY user_id', user_ids]
    find_by_sql(sql).each_with_object({}) do |u, m|
      m[u.user_id] = u.follower_count
    end
  end

  def self.registered_following_counts(user_ids)
    sql = ['SELECT follower_id, COUNT(*) AS following_count FROM follows WHERE follower_id IN (?) GROUP BY follower_id',
      user_ids]
    find_by_sql(sql).each_with_object({}) do |u, m|
      m[u.follower_id] = u.following_count
    end
  end

  def self.profile_per_page
    config.profile.per_page
  end

  # @return [Hash] maps follower slug to the number of seconds in the future to create the follow
  def self.scheduled_follows
    config.scheduled_follows
  end

  def self.config
    Brooklyn::Application.config.users
  end

  protected

  # for each connected profile, execute a given block
  # and merge the results together, eliminating duplicates
  # return an array of the results
  def map_connected_profiles
    person.network_profiles.values.inject(Set.new) do |m, profiles|
      Array.wrap(profiles).inject(m) {|m2, p| m2.merge(yield(p))}
    end.to_a
  end

  def default_for_shipping(address)
    self.postal_addresses.where(ref_type: PostalAddress::RefType::SHIPPING).first.default! if self.shipping_addresses.count == 1
  end
end
