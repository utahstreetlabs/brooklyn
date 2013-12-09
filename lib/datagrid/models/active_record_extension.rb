require 'active_support/core_ext/class/attribute'
require 'kaminari'

# XXX: in the long run, this shouldn't be a responsibility of the model, but rather of an external query builder.
# there could be multiple datagrids using the same model.

module Datagrid
  module ActiveRecordExtension
    extend ActiveSupport::Concern

    included do
      class_attribute :_sort_columns
      class_attribute :_search_columns
      class_attribute :_default_sort_column
      class_attribute :_default_sort_direction
    end

    module ClassMethods
      # Return a scope built up from query, order, page and per scopes. Recognizes the standard +joins+ and +includes+
      # options.
      def datagrid(params, options = {})
        scope = scoped
        [:joins, :includes].each do |opt|
          if options[opt].present?
            scope = scope.send(opt, options[opt])
          end
        end
        scope = datagrid_query_scope(scope, params, options)
        scope = datagrid_order_scope(scope, params, options)
        scope = datagrid_page_scope(scope, params, options)
        scope = datagrid_per_scope(scope, params, options)
        scope
      end

      # Returns a scope including a where clause that performs a case-insensitive substring search against each
      # of +search_columns+. The query term is taken from +params[:query]+.
      def datagrid_query_scope(scope, params, options = {})
        search_cols = self._search_columns || []
        if params[:query].present? && search_cols.any?
          cols = search_cols.inject([]) do |memo, spec|
            if spec.is_a?(Hash)
              # {foo: [:one, :two], bar: :three}
              #   => ['foo.one', 'foo.two', 'bar.three']
              subs = spec.inject([]) do |memo2, (table, tcols)|
                memo2.concat(Array.wrap(tcols).map {|tcol| "#{table}.#{tcol}"})
              end
              memo.concat(subs)
            else
              memo << spec
            end
          end
          where_clause = cols.map {|col| "LOWER(#{col}) LIKE ?"}.join(' OR ')
          query = "%#{params[:query].downcase}%"
          bind_params = [query] * cols.size
          scope = scope.where(where_clause, *bind_params)
        end
        scope
      end

      # Returns a scope including one or more order clauses. Delegates to +#datagrid_sort+ to compute the list of
      # order specifications. The requested column and direction are taken from +params[:sort]+ and
      # +params[:direction]+ respectively.
      def datagrid_order_scope(scope, params, options = {})
        datagrid_sort(params[:sort], params[:direction], options).inject(scope) do |memo, order|
          order = Array.wrap(order)
          column = order[0]
          direction = order.size > 1 ? order[1] : :asc
          memo.order("#{column} #{direction.to_s.upcase}")
        end
      end

      # Returns a scope including limit and offset clauses as per Kaminari. The page number is taken from
      # +params[:page]+.
      def datagrid_page_scope(scope, params, options = {})
        scope.page(params[:page])
      end

      # Returns a scope changing the limit and offset clauses previously applied by +#datagrid_page_scope+ as per
      # Kaminari. The number of records per page is taken from +params[:per]+.
      def datagrid_per_scope(scope, params, options = {})
        if params[:per].present?
          scope = scope.per(params[:per])
        end
        scope
      end

      # Returns an array of order specifications used by +#datagrid_order_scope+ to build order scopes. Each order
      # spec can be represented as a column name (in which case direction defaults to ASC) or as a two-element array of
      # column name and direction.
      #
      # +sort_param+ is checked against +sort_columns+ (or +column_names+, if no sort columns are specified) to see
      # if it represents a valid sort column. If not, the order defaults to +default_sort_column+, or +id+ if that is
      #  not specified.
      #
      # +sort_direction+ must be one of +asc+ or +desc+. If not, the direction defaults to +default_sort_direction+, or
      # +asc+ if that is not specified.
      def datagrid_sort(sort_param, direction_param, options = {})
        sort_cols = self._sort_columns || self.column_names
        default_sort_col = self._default_sort_column || :id
        sort = sort_cols.include?(sort_param) ? sort_param : default_sort_col
        sort = "#{quoted_table_name}.#{sort}" unless sort.to_s.include?('.')
        default_sort_dir = self._default_sort_direction || :asc
        direction = %w[asc desc].include?(direction_param) ? direction_param : default_sort_dir
        [[sort, direction]]
      end

      # Defines the list of columns which can be used for sorting (see +#datagrid_sort+).
      def sort_columns(*columns)
        self._sort_columns = columns
      end

      # Defines the list of columns which will be searched against (see +#datagrid_query_scope+). Each column can be
      # specified as a string or as a hash of string and/or array values representing joined tables (eg
      # +{users: [:name, :title], comments: :text}+).
      def search_columns(*columns)
        self._search_columns = columns
      end

      # Defines the column to sort on if no sort parameter is provided or if the sort parameter is unknown (see
      # +#datagrid_sort+).
      def default_sort_column(column)
        self._default_sort_column = column
      end

      # Defines the direction in which to sort if no direction parameter is provided or if the direction parameter is
      # unknown (see +#datagrid_sort+).
      def default_sort_direction(direction)
        self._default_sort_direction = direction
      end
    end
  end
end
