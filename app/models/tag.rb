require 'datagrid'
require 'stats/trackable'

class Tag < ActiveRecord::Base
  include Featurable
  include Likeable
  include Sluggable
  include Brooklyn::Observable
  include Brooklyn::Sprayer
  include Stats::Trackable

  has_slug :slug
  features_listings

  # an observer handles destroying attachments - the observer needs to build a list of attached listings before
  # destroying the tag so that it can reindex the listings after destroying, but cascading destroys happen before
  # callbacks and observers are allowed to step in
  has_many :listing_attachments, :class_name => 'ListingTagAttachment'
  has_many :listings, :through => :listing_attachments
  has_many :subtags, :foreign_key => :primary_tag_id, :class_name => 'Tag'
  belongs_to :primary_tag, :foreign_key => :primary_tag_id, :class_name => 'Tag'

  default_sort_column :name
  search_columns :name

  attr_accessible :name, :slug, :type, :internal

  def tag_destroy_notifier
    to_reindex = listings
    listing_attachments.destroy_all
    yield(self)
    notify_observers(:after_destroy_with_listings, to_reindex)
  end

  around_destroy :tag_destroy_notifier
  before_destroy { |tag| tag.primary?? tag.promote_all : true}

  # Merges the identified tags into this one by updating the subtags' primary tag id to this tag id
  def merge(ids)
    ids = ids.flat_map {|id| Tag.find(id).subtags.map(&:id) << id.to_i}.reject {|id| id == self.id}.sort
    if ids.any?
      logger.debug("Updating primary tag id for tags #{ids}")
      Tag.update_all({primary_tag_id: self.id}, {id: ids})
      notify_observers(:after_merge, ListingTagAttachment.select(:listing_id).where(tag_id: ids).map(&:listing_id))
    end
  end

  def merge_by_name(names)
    merge(Tag.where(name: names).map(&:id))
  end

  def promote
    logger.debug("Promoting subtag #{self.id} (primary #{primary.id}) with #{self.listings.count} listings")
    promoted_listings = listings
    # unfeature all listings featured with primary tag
    # XXX (bcm): trying to figure out what kind of sense this makes. why would the listing be attached to the subtag
    # but featured for the primary tag? what are we actually trying to accomplish here?
    listing_attachments.each {|a| a.listing.unfeature_for_tag(primary)}
    self.primary_tag = nil
    self.save
    notify_observers(:after_promote, promoted_listings)
  end

  # Promotes all subtags of the primary tag. Returns true if all successfully promoted, false otherwise.
  def promote_all
    subtags.map { |subtag| subtag.promote }.all?
  end

  def subtag?
    !primary?
  end

  def primary?
    primary_tag_id.nil?
  end

  # Can't override the belongs to association
  def primary
    primary_tag || self
  end

  def related_tags
    [primary] + primary.subtags
  end

  def related_tag_ids
    related_tags.map(&:id)
  end

  # Returns an array of tags corresponding to the provided names.
  # @see #find_or_create_by_name(name)
  def self.find_or_create_all_by_name(names = [])
    Array(names).map {|n| find_or_create_by_name(n)}.uniq
  end

  # Returns a tag corresponding to the provided name. The tag is created if one with that name does not already exist.
  def self.find_or_create_by_name(name, other_attrs = {})
    tag = find_by_slug(Tag.compute_slug(name)) || new(other_attrs.merge(name: name))
    tag.save! if tag.new_record?
    tag
  end

  def self.new_size_tag(name)
    tag = new(name: name)
    tag.type = 's'
    tag.save!
    tag
  end

  # Generate a hash of Tag => listing_count for a set of listings,
  # that includes all tags that are at least associated to1 listing.
  def self.with_count_for_listings(listings, except_slugs=[])
    tags = select("tags.*, COUNT(listing_tag_attachments.listing_id) as listing_count").
      joins(:listing_attachments).
      where("listing_tag_attachments.listing_id" => listings.map(&:id)).
      group("tags.name").
      order("tags.name ASC")

    tags = tags.where("tags.slug NOT IN (?)", except_slugs) if except_slugs.any?

    tags.all.inject Hash.new(0) do |tags_with_counts, tag|
      tags_with_counts[tag] = tag["listing_count"]
      tags_with_counts
    end
  end

  def self.find_matching(name, options = {})
    if name.present?
      limit = options.fetch(:limit, 10)
      type = options[:type].present?? options[:type] : nil
      primary = (options[:primary] == "1" || options[:primary] == true)
      scope = select("name, slug").where('name like ?', "#{name.strip}%")
      scope = scope.where(primary_tag_id: nil) if primary
      scope = scope.where(type: type).order(:name).limit(limit)
    else
      []
    end
  end

  def self.find_primaries_matching(name, options = {})
    Tag.find_matching(options.merge(condition: :primary))
  end

  def self.find_ids_for_slugs(slugs)
    Tag.select(:id).where(slug: slugs).map(&:id)
  end

  def self.primary_tags(options = {})
    scope = where(primary_tag_id: nil)
    scope = scope.where(type: options[:type]) if options[:type].present?
    scope = scope.includes(:subtags) if options[:with_subtags]
    scope
  end

  # returns the distance into the past to show stories about a tag when a tag is liked
  def self.like_story_window
    Brooklyn::Application.config.tags.likes.story_window
  end

  # returns the cutoff time for showing stories about a tag when a tag is liked
  def self.like_story_start_date
    (Time.now - like_story_window).utc
  end

  def self.inheritance_column
    # we're using a type column but not in a STI sense, so misdirect AR
    'typ'
  end

  # @option options [Integer] :limit (100)
  def self.find_popular(type, options = {})
    where(type: type).order(:name).limit(options.fetch(:limit, 100))
  end

  def self.find_or_create_from_hashtags(hashtags)
    find_or_create_all_by_name(hashtags.map { |k,v| v['name'] })
  end
end
