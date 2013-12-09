class SearchBrowseController < ApplicationController
  include Controllers::InfinitelyScrollable
  include Controllers::PathTags

  redirect_legacy_tags_to_path_tags
  set_category
  parameterize_path_tags
  skip_requiring_login_only
  skip_action_event only: :browse

  def browse
    do_search(:listings_browse)
    respond_to do |format|
      format.html
      format.json { render_jsend(success: json_results) }
    end
  end

  def new_arrivals
    do_search(:new_arrivals_browse, approved: true, approved_since: Listing.browse_new_arrivals_since)
    respond_to do |format|
      format.html { render :browse }
      format.json { render_jsend(success: json_results) }
    end
  end

  protected
    def do_search(event, options = {})
      @page_manager = @searcher = ListingSearcher.new(params.merge(includes: [:size, {seller: :person}]).merge(options))
      if @searcher.error
        set_flash_message(:alert, :search_error, now: true)
      else
        @results = ListingResults.new(viewer, @searcher.all)
        fire_browse_event(event, @searcher, @category)
      end
    end

    def time(times, label, &block)
      start = Time.now
      block.call
      times[label] = Time.now - start
    end

    def json_results
      vc = view_context
      results = {}
      times = {}
      time(times, :cards) { results[:cards] = vc.feed_cards(@results, source: browse_page_source) }
      if params[:facets]
        time(times, :facets) do
          time(times, :title) { results[:title] = vc.listing_search_browse_title(@searcher) }
          time(times, :categories) do
            if feature_enabled? 'horizontal_browse'
              results[:categories] = vc.category_list_items(@searcher.categories.alphabetical)
            else
              results[:categories] = vc.category_list_items(@searcher.categories.unselected)
            end
          end
          time(times, :tags) { results[:tags] = vc.facet_list_items(@searcher.tags.unselected, key: :tags) }
          time(times, :prices) do
            results[:prices] = vc.price_range_checkboxes(@searcher.price_ranges.ordered)
          end
          time(times, :sizes) { results[:sizes] = vc.facet_checkboxes(@searcher.sizes.alphabetical, key: :sizes) }
          time(times, :brands) { results[:brands] = vc.facet_checkboxes(@searcher.brands.alphabetical, key: :brands) }
          time(times, :conditions) do
            results[:conditions] = @category.present?? vc.condition_checkboxes(@searcher.conditions.alphabetical) : []
          end
          time(times, :selections) { results[:selections] = vc.facet_selections(@category, @searcher) }
          time(times, :count) { results[:count] = vc.number_with_delimiter(@searcher.total) }
          time(times, :sorts) { results[:sorts] = vc.listings_sort_links(@searcher) }
        end
        time(times, :titles) do
          results[:titles] = {
            categories: vc.facet_title('category', @searcher.categories.selected),
            prices: vc.facet_title('price', @searcher.price_ranges.selected, name: 'Prices'),
            sorts: t("search_browse.browse.sort.#{@searcher.sort_key}")
          }
        end
      end
      logger.info("Found json search results with times: #{times.to_json}")
      results[:more] = next_page_path unless last_page?
      results
    end

    def selected_featurable(category, tags)
      category || (tags.any?? tags.first : nil)
    end

    def url_for_params(parameters)
      browse_for_sale_path_tags_path(@category, parameters)
    end

    def fire_browse_event(event, searcher, category)
      options = {user: current_user, request: request, query: params[:search],
        hitcount: searcher.size, category: category, tags: searcher.selected_tags,
        dimensions: searcher.selected_conditions, listings: searcher.all.map(&:id)}
      fire_event(event, options)
    end
end
