class ListingFeature < ActiveRecord::Base
  belongs_to :featurable, polymorphic: true
  belongs_to :listing

  acts_as_list scope: [:featurable_id, :featurable_type]

  validates :featurable_id, uniqueness: {scope: [:listing_id, :featurable_type]}

  attr_accessible :featurable, :listing, :position
end
