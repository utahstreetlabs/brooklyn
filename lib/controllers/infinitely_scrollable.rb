# For inclusion in controllers providing data to infinitely scrollable views.
# The including controller must set the instance variable @page_manager, which at the least should implement the
# mehods +current_page+ and +last_page?+

module Controllers
  module InfinitelyScrollable
    extend ActiveSupport::Concern

    included do |m|
      helper_method :results_tag_params
    end

    def viewer
      logged_in?? current_user : nil
    end

    def results_tag_params
      last_page?? {} : { data: { more_url: next_page_path } }
    end

    def last_page?
      page_manager.last_page?
    end

    def url_for_params(params)
      url_for(params)
    end

    def next_page_path
      params[:page] = page_manager.current_page + 1
      params[:only_path] = true
      url_for_params(params)
    end

    def page_manager
      @page_manager
    end

  end
end
