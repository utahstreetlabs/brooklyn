class Connect::WhoToFollowController < ApplicationController
  include Controllers::InfinitelyScrollable
  include Controllers::ProfileScoped
  layout 'connect'

  # This method displays results from suggested users to follow.
  # This method responses differently for html and json requests.  The intial
  # request is an html call, subsquent requests are json, which retrieves
  # more suggestions for the user to follow
  def index
    respond_to do |format|
      format.html do
         build_user_strips(Brooklyn::Application.config.connect.who_to_follow.per_page)
      end
      format.json do
        page = params[:page].to_i
        build_user_strips( params[:count].to_i, page )
        user_strips = @user_strips.map { |l| view_context.who_to_follow_user_strip(l) }

        results = { cards: user_strips }
        unless last_page?
          results[:more] = connect_who_to_follow_index_path(format: :json, count: params[:count].to_i, page: page + 1)
        end
        render_jsend(success: results)
      end
    end
  end

  protected

  def page_manager
    @user_strips
  end

  private

  def build_user_strips(count, page = 0)
    follow_suggestions = current_user.follow_suggestions(count, offset: page)
    @user_count = count
    @user_strips = UserStripCollection.new(current_user, follow_suggestions, page: page, total: params[:count])
  end
end
