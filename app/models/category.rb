require 'datagrid'

class Category < ActiveRecord::Base
  include Sluggable
  include Featurable

  has_slug :slug
  features_listings

  has_many :dimensions
  has_many :listings

  scope :order_by_name, order(:name)

  default_sort_column :name
  search_columns :name

  attr_accessible :name, :slug

  def dimensions_with_values
    dimensions.includes(:values).order(:name).all
  end

  def self.find_with_at_least_one_active_listing
    find_by_sql("SELECT * FROM categories WHERE id IN (SELECT DISTINCT category_id FROM listings WHERE state = 'active') ORDER BY name")
  end
end
