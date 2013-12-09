class Dimension < ActiveRecord::Base
  include Sluggable

  has_slug :slug

  belongs_to :category
  has_many :values, class_name: 'DimensionValue', order: 'position'

  attr_accessible :name, :slug

  # Builds a hash of dimension => values
  #
  # If it's passed a block, it passes the scope of a_dimension.values to it and
  # returns whatever the block returns as the hash values.
  #
  # If a dimension has no values (or the block returns an object that returns
  # false when asked if #present?) then the dimension is excluded from the hash.
  def self.grouped_with_values
    all.inject({}) do |filtered, dimension|
      values = block_given? ? yield(dimension.values, dimension) : dimension.values
      filtered[dimension] = values if values.present?
      filtered
    end
  end
end
