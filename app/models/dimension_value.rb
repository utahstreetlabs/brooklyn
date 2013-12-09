class DimensionValue < ActiveRecord::Base
  belongs_to :dimension
  has_many :listing_attachments, :class_name => "DimensionValueListingAttachment"
  has_many :listings, :through => :listing_attachments

  acts_as_list scope: :dimension

  validates :value, :presence => true, :length => {:maximum => 64}, :uniqueness => {:scope => :dimension_id}

  attr_accessible :value, :position

  # facade for facet helpers in search
  def name
    value
  end

  def slug
    id
  end

  # Generate a hash of DimensionValue => listing_count for a set of listings,
  # that includes all values that have at least 1 listing.
  def self.with_count_for_listings(listings, except_values=[])
    values = select("dimension_values.*, COUNT(dimension_value_listing_attachments.listing_id) AS listing_count").
      joins(:listing_attachments).
      where("dimension_value_listing_attachments.listing_id" => listings.map(&:id)).
      group("dimension_values.value").
      order("dimension_values.value ASC")

    values = values.where("dimension_values.value NOT IN (?)", except_values) if except_values.any?

    values.all.inject Hash.new(0) do |values_with_counts, value|
      values_with_counts[value] = value["listing_count"]
      values_with_counts
    end
  end
end
