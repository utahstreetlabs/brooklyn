class ListingSearcher
  attr :scope
  attr :query
  attr :category
  attr :selected_tags
  attr :selected_price_ranges
  attr :selected_brands
  attr :selected_sizes
  attr :selected_conditions
  attr :page
  attr :per_page
  attr :seller_id
  attr :exclude_seller_id
  attr :approved
  attr :approved_since
  attr :created_after
  attr :created_before
  attr :with_sold

  SORT_OPTIONS = feature_enabled?('horizontal_browse') ? {
    # Sort options prescribed by product spec. Don't change unless required by spec.
    relevance: [[:score, :desc]],
    date_state: [[:state, :asc], [:created_at, :desc]],
    date: [[:created_at, :desc]],
    popular: [[:likes, :desc]],
    price: [[:price, :desc]],
    rprice: [[:price, :asc]]
  } : {
    price: [[:price, :desc]],
    rprice: [[:price, :asc]],
    popular: [[:likes, :desc]],
    date: [[:created_at, :desc]],
    date_state: [[:state, :asc], [:created_at, :desc]],
    relevance: [[:score, :desc]]
  }

  # don't show these options in the search / browse sort menu:
  HIDDEN_SORT_OPTIONS = [:date_state]

  PRICE_RANGES = [
    ['Under $25', (0..24.99)],
    ['$25-$50', (25..49.99)],
    ['$50-$100', (50..99.99)],
    ['$100-$250', (100..249.99)],
    ['Over $250', (250..Float::MAX)]
  ]

  def initialize(params, scope=Listing.scoped)
    @scope = scope
    @query = params.fetch(:search, nil)
    @seller_id = params.fetch(:seller_id, nil)
    @seller_id = @seller_id.to_i if @seller_id
    @category = params.key?(:category) ? Category.find_by_slug(params[:category]) : nil
    @selected_tags = params.fetch(:tags, []).select { |t| t.present? }
    @selected_price_ranges = params.fetch(:prices, []).map(&:to_i)
    @selected_sizes = params.fetch(:sizes, [])
    @selected_brands = params.fetch(:brands, [])
    @selected_conditions = params.fetch(:conditions, [])
    @sort_options = SORT_OPTIONS.dup
    @sort_options.delete(:relevance) unless @query.present?
    @sort_param = params[:sort]
    @page = params[:page].to_i
    @page = 1 unless @page > 0
    @per_page = params[:per_page].to_i
    @per_page = Brooklyn::Application.config.listings.browse.per_page unless @per_page > 0
    @includes = params.fetch(:includes, [])
    @exclude_seller_id = params[:exclude_seller] || params[:exclude_sellers]
    @approved = params[:approved]
    @approved_since = params[:approved_since]
    @with_sold = params[:with_sold]
    @created_after = params[:created_after]
    @created_after = DateTime.strptime(@created_after, '%s') if @created_after.is_a?(String)
    @created_before = params[:created_before]
    @created_before = DateTime.strptime(@created_before, '%s') if @created_before.is_a?(String)
  end

  def scoreable?
    @query.present?
  end

  def default_sort_key
    scoreable?? :relevance : (with_sold? ? :date_state : :date)
  end

  def order_args
    SORT_OPTIONS[sort_key]
  end

  def sort_keys
    @sort_options.keys.reject { |k| HIDDEN_SORT_OPTIONS.include?(k) }
  end

  def sort_key
    @sort_key ||= (@sort_param.present?? @sort_param.to_sym : default_sort_key)
  end

  def with_sold?
    !!@with_sold
  end

  def any?
    size > 0
  end

  def all
    @all ||= ResultsPage.new((search ? search.results : []), current_page: page, num_pages: num_pages,
      per_page: per_page)
  end

  def size
    @size ||= search ? search.hits.count : 0
  end

  def total
    search ? search.total : 0
  end

  def current_page
    page
  end

  def num_pages
    search ? (search.total / per_page.to_f).ceil : 1
  end

  def last_page?
    max_page = (total / per_page).ceil + 1
    error ? true : max_page <= page
  end

  def query
    @query || ''
  end

  def tags
    @tags ||= Facet.new(:tag_facets, search, selected_tags)
  end

  def price_ranges
    @price_ranges ||= RangeFacet.new(:price, search, selected_price_ranges, PRICE_RANGES)
  end

  def conditions
    @conditions ||= Facet.new(:condition_facet, search, selected_conditions)
  end

  def categories
    @categories ||= Facet.new(:category_facet, search, category.present?? [category.slug] : [])
  end

  def sizes
    @sizes ||= Facet.new(:size_facet, search, selected_sizes)
  end

  def brands
    @brands ||= Facet.new(:brand_facet, search, selected_brands)
  end

  def error
    search ? nil : @error
  end

private
  def search
    unless defined?(@search)
      @search = begin
        scope.search(:include => @includes) do
          fulltext query if query.present?

          any_of do
            with(:state).equal_to(:active)
            with(:state).equal_to(:sold) if with_sold?
          end

          category_filter = category.present?? with(:category_slug).equal_to(category.slug) : nil
          with(:tag_slugs).all_of(selected_tags) if selected_tags.any?
          brand_filter = selected_brands.any?? with(:brand_slug).any_of(selected_brands) : nil
          size_filter = selected_sizes.any?? with(:size_slug).any_of(selected_sizes) : nil
          condition_filter = selected_conditions.any?? with(:condition_slug).any_of(selected_conditions) : nil
          price_range_filter = if selected_price_ranges.any?
            any_of { selected_price_ranges.each { |i| with(:price, PRICE_RANGES[i].last) } }
          else
            nil
          end
          if exclude_seller_id
            without(:seller_id).equal_to(exclude_seller_id)
          elsif seller_id
            with(:seller_id).equal_to(seller_id)
          end
          with(:approved).equal_to(approved) if approved.present?
          with(:approved_at).greater_than(approved_since.ago) if approved_since.present?
          with(:created_at).greater_than(created_after) if created_after.present?
          with(:created_at).less_than(created_before) if created_before.present?

          facet(:category_facet, zeros: feature_enabled?('horizontal_browse'),
                exclude: (feature_enabled?('horizontal_browse') ? category_filter : nil))
          facet(:tag_facets)
          facet(:price, exclude: price_range_filter)
          facet(:brand_facet, exclude: brand_filter)
          facet(:size_facet, exclude: size_filter)
          facet(:condition_facet, exclude: condition_filter)

          order_args.each do |o|
            order_by(*o)
          end
          paginate(page: page, per_page: per_page)
        end
      rescue Errno::ECONNREFUSED => e
        Rails.logger.error("Search index connection refused")
        @error = e
        nil
      end
    end
    @search
  end

  class Facet
    def initialize(facet, search_result, selected)
      @cache = if search_result
        search_result.facet(facet).rows.each_with_object([]) do |row, list|
          slug, name = row.value.split('#', 2)
          list << [OpenStruct.new(slug: slug, name: name), selected.include?(slug), row.count]
        end
      else
        []
      end
    end

    # returns the instances for 'your navigation'
    def selected
      @selected ||= @cache.select { |i,s,c| s }.map { |i,s,c| i }
    end

    def selected_names
      @selected_names ||= @cache.select { |i,s,c| s }.map { |i,s,c| i.name }
    end

    # returns the hash for the sidebar
    def unselected
      @unselected ||= @cache.reject { |i,s,c| s }
    end

    def alphabetical(&block)
      @alphabetical ||= block_given?? @cache.sort_by(&block) : @cache.sort_by { |i,s,c| i.name }
    end

    def ordered
      @ordered ||= @cache.dup
    end

    def warn_nil_instance(facet, row)
      Airbrake.notify(error_class: "Searcher found nil row.instance",
                      error_message: "This probably means the index is out of sync",
                      parameters: {facet: facet, row: row})
    end
  end

  class RangeFacet < Facet
    # sunspot's query facets look like they would solve this problem, but don't support excludes in the faceting
    # which means we can't use them for multi-select
    def initialize(facet, search_result, selected, ranges)
      if search_result
        counts = ranges.map { |r| 0 }
        search_result.facet(facet).rows.each do |row|
          ranges.each_with_index do |range, index|
            if range.last.include?(row.value.to_f)
              counts[index] = counts[index] + row.count
              break
            end
          end
        end
        @cache = ranges.each_with_index.map do |range,index|
          [OpenStruct.new(slug: index.to_s, name: range.first), selected.include?(index), counts[index]]
        end
      end
    end
  end

  # ripped off of Kaminari::PaginatableArray, which we can't use because it assumes WillPaginate and what not
  class ResultsPage < Array
    attr_reader :current_page, :num_pages, :per_page, :limit_value, :offset_value

    def initialize(results, options = {})
      @current_page = options[:current_page]
      @num_pages = options[:num_pages]
      @per_page = options[:per_page]
      @limit_value = @per_page
      @offset_value = 0
      super(results[@offset_value, @limit_value])
    end
  end
end
