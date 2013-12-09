class Interest < ActiveRecord::Base
  include Brooklyn::UniqueIndexEnforceable

  GLOBAL_INTEREST_ID = -1

  attr_accessible :name, :gender, :cover_photo, :onboarding, as: :admin
  attr_accessible :position
  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :cover_photo, presence: true
  validates :gender, inclusion: {in: [true, false]}, allow_blank: true
  validates :onboarding, inclusion: {in: [true, false]}

  acts_as_list scope: 'onboarding = 1', top_of_list: 0

  scope :by_position, order(:position)
  scope :by_order, order('RAND()')
  scope :female_or_all, where('gender = ? OR gender IS NULL', false)
  scope :male_or_all, where('gender = ? OR gender IS NULL', true)

  mount_uploader :cover_photo, InterestCoverPhotoUploader

  has_many :suggestions, class_name: 'UserSuggestion', dependent: :destroy
  has_many :user_interests, dependent: :destroy
  has_many :autofollows, class_name: 'CollectionAutofollow', dependent: :destroy
  has_many :autofollow_collections, through: :autofollows

  scope :by_name, order(:name)

  def suggested_user_list
    suggestions.order(:position).includes(:user).map(&:user)
  end

  def autofollow_collection_list
    autofollows.includes(:collection).map(&:collection)
  end

  def suggested_user_count
    suggestions.count
  end

  # @raise ActiveRecord::RecordNotUnique if the user is already in the suggested list
  def add_to_suggested_user_list!(user)
    logger.debug("Adding user #{user.id} to suggested user list for interest #{self.id}")
    suggestions.create!(user_id: user.id)
  end

  # @raise ActiveRecord::RecordNotFound if the user is not already in the suggested list
  def move_within_suggested_user_list!(user, position)
    suggestion = suggestion_for_user(user)
    logger.debug("Moving user #{user.id} to position #{position} in suggested user list for interest #{self.id}")
    suggestion.insert_at(position.to_i)
    suggestion.save!
  end

  def remove_from_suggested_user_list(user)
    logger.debug("Removing user #{user.id} from suggested user list for interest #{self.id}")
    suggestions.where(user_id: user.id).destroy_all
  end

  def remove_from_autofollow_collection_list(collection)
    logger.debug("Removing collection #{collection.id} from autofollow collection list for interest #{self.id}")
    autofollows.where(collection_id: collection.id).destroy_all
  end

  def in_suggested_user_list?(user)
    suggestions.where(user_id: user.id).any?
  end

  def suggestion_for_user(user)
    suggestion = suggestions.where(user_id: user.id).first
    raise ActiveRecord::RecordNotFound unless suggestion
    suggestion
  end

  def move_within_onboarding_list!(position)
    logger.debug("Moving interest #{self.id} to position #{position} in onboarding list")
    insert_at(position.to_i)
    save!
  end

  def remove_from_onboarding_list!
    logger.debug("Removing interest #{self.id} from onboarding list")
    update_attributes!({onboarding: false}, without_protection: true)
  end

  def listings
    Listing.joins(collections: :autofollowed_for_interests).where(interests: {id: self.id})
  end

  def self.suggested_user_list_counts
    UserSuggestion.count_by_interest
  end

  def self.autofollow_collection_list_counts
    CollectionAutofollow.count_by_interest
  end

  def self.interested_user_list_counts
    UserInterest.count_by_interest
  end

  def self.num_required_for_signup
    config.signup.required
  end

  def self.num_signup_options
    config.signup.options
  end

  def self.config
    Brooklyn::Application.config.interests
  end

  def self.global
    Interest.find(GLOBAL_INTEREST_ID)
  end

  def self.all_but_global
    Interest.where('id != ?', [GLOBAL_INTEREST_ID])
  end

  def self.onboarding_list_by_position
    where(onboarding: true).limit(self.num_signup_options).by_position
  end

  # @option options [String] :gender if +:male+ or +:female+, excludes interests tagged for the opposite gender (ie
  #                                     +:male+ will return only (male + all) interests)
  def self.onboarding_list_by_rand(options = {})
    relation = where(onboarding: true).limit(self.num_signup_options).by_order

    case options[:gender]
    when :male then relation = relation.male_or_all
    when :female then relation = relation.female_or_all
    # anything else means to ignore gender altogether
    end

    relation
  end

  def self.add_to_onboarding_list!(ids)
    ids = Array.wrap(ids).map(&:to_i)
    ids.delete(global.id) # global interest can never be on the onboarding list
    logger.debug("Adding interests #{ids} to onboarding list")
    update_all({onboarding: true}, id: ids)
  end

  def self.remove_from_onboarding_list!(ids)
    ids = Array.wrap(ids).map(&:to_i)
    logger.debug("Removing interests #{ids} from onboarding list")
    update_all({onboarding: false}, id: ids)
  end
end
