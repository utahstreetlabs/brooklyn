class DimensionValueListingAttachment < ActiveRecord::Base
  include Brooklyn::UniqueIndexEnforceable

  belongs_to :listing
  belongs_to :dimension_value
  has_unique_index :index_dv_listing_attachments_on_listing_id_and_dv_id, :dimension_value, :listing
end
