module OrderDatagrid
  extend ActiveSupport::Concern

  included do
    default_sort_column :updated_at
    default_sort_direction :desc
    search_columns :reference_number, listings: :title, users: :name, sellers_listings: :name
  end

  module ClassMethods
    def datagrid_sort(sort_param, direction_param, options = {})
      case sort_param
      when 'listing' then [['listings.title', direction_param]]
      when 'seller' then [['sellers_listings.name', direction_param]]
      when 'buyer' then [['users.name', direction_param]]
      when 'handling_expires' then [['(confirmed_at + INTERVAL listings.handling_duration SECOND)', direction_param]]
      else super
      end
    end
  end
end
