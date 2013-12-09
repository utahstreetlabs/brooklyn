module Datagrid
  # This class takes an array of objects and interfaces with datagrid table stuff.
  class ArrayDatagrid < SimpleDelegator
    def initialize(collection, params)
      collection = collection.sort_by { |item| sort_key(item, params[:sort]) } if params[:sort]
      collection = collection.reverse if params[:direction] == 'desc'
      limit = 30
      page = params[:page].present?? params[:page].to_i : 1
      offset = (page-1) * limit
      super(Kaminari::PaginatableArray.new(collection, limit: limit, offset: offset))
    end

    def sort_key(item, attr)
      attr = attr.to_sym
      key = item.is_a?(Hash) ? item[attr] : item.send(attr)
      [key ? 1 : 0, key]
    end
  end
end
