class Offer < ActiveRecord::Base
  include Brooklyn::Observable
  include Brooklyn::Sprayer
  include Sluggable

  has_many :credits
  has_many :seller_offers, dependent: :destroy
  has_many :sellers, through: :seller_offers
  has_many :tag_offers, dependent: :destroy
  has_many :tags, through: :tag_offers

  has_slug :uuid, attribute: nil, max_length: 64

  mount_uploader :landing_page_background_photo, OfferLandingPageBackgroundPhotoUploader
  mount_uploader :fb_story_image, OfferFbStoryImageUploader

  attr_accessible :name, :destination_url, :info_url, :seller_slugs, :amount, :minimum_purchase, :duration, :available,
    :new_users, :existing_users, :signup, :expires_at, :ab_tag, :descriptor, :landing_page_headline, :uuid,
    :landing_page_text, :landing_page_background_photo, :'expires_at(1i)', :'expires_at(2i)', :'expires_at(3i)',
    :'expires_at(4i)', :'expires_at(5i)', :fb_story_name, :fb_story_caption, :fb_story_description, :fb_story_image,
    :tag_slugs, :no_purchase_users, :no_credit_users

  validates :name, presence: true, length: {maximum: 255, allow_blank: true}
  validates :descriptor, presence: true, length: {maximum: 255, allow_blank: true}
  validates :ab_tag, length: {maximum: 255, allow_blank: true}
  # uuid validated by sluggable
  validates :destination_url, length: {maximum: 255, allow_blank: true}, url: {allow_blank: true}
  validates :info_url, length: {maximum: 255, allow_blank: true}, url: {allow_blank: true}
  validates :available, presence: true, numericality: {integer_only: true, greater_than: 0, allow_blank: true}
  validates :amount, presence: true, numericality: {greater_than: 0, allow_blank: true}
  validates :minimum_purchase, presence: true, numericality: {greater_than_or_equal_to: 0, allow_blank: true}
  validates :duration, presence: true,
            numericality: {integer_only: true, greater_than: 0, less_than_or_equal_to: 43200, allow_blank: true}
  validates :expires_at, date: {after: Proc.new { Date.current }, allow_blank: true}
  validates :landing_page_headline, length: {maximum: 255, allow_blank: true}
  validates :fb_story_name, length: {maximum: 255, allow_blank: true}
  validates :fb_story_caption, length: {maximum: 255, allow_blank: true}
  validate :valid_eligibility
  validate :valid_fb_story_image

  # don't bother normalizing seller or tag slugs as they are handled explicitly in the setter method
  # uuid is normalized by sluggable
  normalize_attributes :name, :descriptor, :ab_tag, :destination_url, :info_url, :expires_at, :landing_page_headline,
    :fb_story_name, :fb_story_caption, :fb_story_description, with: [:squish, :blank]
  normalize_attributes :landing_page_text, with: [:strip, :blank] # interior whitespace is significant here
  normalize_attributes :amount, :minimum_purchase, with: [:squish, :blank, :currency]
  normalize_attributes :available, :duration, with: [:squish, :blank, :integer]
  normalize_attributes :new_users, :existing_users, :signup, with: :boolean

  def has_eligibility?
    new_users? || existing_users?
  end

  def valid_eligibility
    unless has_eligibility?
      errors[:eligibility] << I18n.t('activerecord.errors.models.offer.attributes.eligibility.blank')
    end
  end

  def valid_fb_story_image
    if not fb_story_image?
      errors[:fb_story_image] << I18n.t('activerecord.errors.models.offer.attributes.fb_story_image.blank')
    elsif not (fb_story_image.valid_size? && fb_story_image.valid_aspect_ratio?)
      errors[:fb_story_image] << I18n.t('activerecord.errors.models.offer.attributes.fb_story_image.invalid_size',
                                        width: OfferFbStoryImageUploader::MIN_WIDTH,
                                        height: OfferFbStoryImageUploader::MIN_HEIGHT,
                                        aspect_ratio: OfferFbStoryImageUploader::MAX_ASPECT_RATIO_STR)
    end
  end

  def seller_specific?
    sellers.any?
  end

  def seller_slugs
    sellers.map(&:slug).sort.join(', ')
  end

  # Note that any existing sellers that are not specified in the new slug string are immediately deleted, while any
  # sellers specified in the string that are not yet attached to the offer have seller offers built but not yet saved.
  def seller_slugs=(slug_str)
    slug_str ||= ''
    slugs = slug_str.split(/\s*,\s*/)
    new_seller_ids = Set.new(slugs.any? ? User.where(slug: slugs).map(&:id) : [])
    old_seller_ids = Set.new(sellers.map(&:id))
    ids_to_delete = old_seller_ids - new_seller_ids
    if ids_to_delete.any?
      self.seller_offers.where(seller_id: ids_to_delete.to_a).each { |o| self.seller_offers.delete(o) }
    end
    ids_to_add = new_seller_ids - old_seller_ids
    if ids_to_add.any?
      ids_to_add.each { |id| self.seller_offers.build({seller_id: id}, without_protection: true) }
    end
  end

  def tag_specific?
    tags.any?
  end

  def tag_slugs
    tags.map(&:slug).sort.join(', ')
  end

  # Note that any existing tags that are not specified in the new slug string are immediately deleted, while any
  # tags specified in the string that are not yet attached to the offer have tag offers built but not yet saved.
  def tag_slugs=(slug_str)
    slug_str ||= ''
    slugs = slug_str.split(/\s*,\s*/)
    new_tag_ids = Set.new(slugs.any? ? Tag.where(slug: slugs).map(&:id) : [])
    old_tag_ids = Set.new(tags.map(&:id))
    ids_to_delete = old_tag_ids - new_tag_ids
    if ids_to_delete.any?
      self.tag_offers.where(tag_id: ids_to_delete.to_a).each { |o| self.tag_offers.delete(o) }
    end
    ids_to_add = new_tag_ids - old_tag_ids
    if ids_to_add.any?
      ids_to_add.each { |id| self.tag_offers.build({tag_id: id}, without_protection: true) }
    end
  end

  def earn(user)
    # XXX: refactor to use Credit#grant_if_eligible! - would unify eligibility checking and credit creation, and it
    # would let us replace the offer controller observer with the top messaging system built into Credit#eligibility.
    reason = if new_users_only? && !user.just_registered?
      :invalid_new_only
    elsif existing_users_only? && user.just_registered?
      :invalid_existing_only
    elsif !available?
      :invalid_total_user_limit
    elsif earned_by_user?(user)
      :invalid_per_user_limit
    elsif no_credit_users? && user.has_available_credit?
      :invalid_has_credit
    elsif no_purchase_users? && user.has_purchased?
      :invalid_has_purchased
    # do this one last, because it can be expensive
    elsif !user.person.minimally_connected?(self.class.min_followers, permit_on_error: true)
      :invalid_user_connectivity
    end

    if reason
      user.add_top_message(InviteeCreditMessage.new(0, reason)) unless self.signup && reason == :invalid_new_only
    else
      credit = self.credits.build(amount: amount)
      credit.user = user
      credit.expires_at = (Time.now + duration.minutes) if duration
      credit.save!
      user.add_top_message(InviteeCreditMessage.new(amount, :invitee_credited))
      Offers::AfterEarnedJob.enqueue(self.id, user.id)
      credit
    end
  end

  def new_users_only?
    new_users? && !existing_users?
  end

  def existing_users_only?
    existing_users? && !new_users?
  end

  def available?
    (earned < available) && (expires_at.nil? || (expires_at > Time.zone.now))
  end

  def earned_by_user?(user)
    self.credits.where(user_id: user.id).count > 0
  end

  def earned
    self.credits.count
  end

  def display_name
    (name && name.length > 0) ? name : self.class.default_name
  end

  class << self
    # get all the offers from which credits can be applied to this listing
    def valid_for_listing(listing_or_id)
      listing = listing_or_id.is_a?(Listing) ? listing_or_id : Listing.find(listing_or_id)
      seller_table = SellerOffer.quoted_table_name
      tag_table = TagOffer.quoted_table_name
      no_tag_or_seller = "(#{seller_table}.offer_id IS NULL AND #{tag_table}.offer_id IS NULL)"
      seller_matches = "(#{seller_table}.seller_id = #{listing.seller_id})"
      tag_matches = "(#{tag_table}.tag_id IN (#{listing.tags.map(&:id).join(',')}))" if listing.tags.any?
      scope = where("(#{[no_tag_or_seller, seller_matches, tag_matches].compact.join(' OR ')}) AND " +
              "#{quoted_table_name}.minimum_purchase <= #{listing.price}")

      scope.all(
        select: "#{quoted_table_name}.*",
        joins: "LEFT JOIN #{seller_table} ON #{quoted_table_name}.id = #{seller_table}.offer_id " +
               "LEFT JOIN #{tag_table} ON #{quoted_table_name}.id = #{tag_table}.offer_id"
      )
    end

    # return the count of credits associated with each offer as a hash
    def earned_by_id
      Credit.where('offer_id IS NOT NULL').count(group: :offer_id)
    end

    def min_followers
      Brooklyn::Application.config.offers.min_followers
    end

    def default_name
      I18n.t('offers.default_name')
    end

    def signup_offer(reload = false)
      if reload || !defined?(@signup_offer)
        @signup_offer = where(signup: true).where(['(expires_at IS NULL OR expires_at > ?)', Time.zone.now.utc]).first
        @signup_offer = nil unless (@signup_offer.present? && @signup_offer.available?)
      end
      @signup_offer
    end

    def compute_slug(input)
      # input will be nil since we don't have a sluggable field. we can just ignore it.
      SecureRandom.uuid
    end
  end
end
