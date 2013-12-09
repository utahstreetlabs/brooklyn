class HomeController < ApplicationController
  include Controllers::SignupFlow
  include Controllers::TopMessages
  include Controllers::InviteBar
  include Controllers::InfinitelyScrollable

  skip_before_filter :require_login_only
  before_filter :require_not_logged_in, :only => :signup, unless: :redirected_from_dashboard?
  skip_enable_autologin
  skip_store_login_redirect
  before_filter { store_login_redirect(params[:d]) if redirected_from_dashboard? }
  before_filter :enable_autologin, only: [:signup], if: :redirected_from_dashboard?

  # XXX: I bet we can split this into separate controllers and use routing constraints to direct to the appropriate
  # controller based on authentication state

  def index
    return render_logged_in if logged_in?
    return redirect_to_signup_flow_entry_point if connected? && !feature_enabled?('onboarding.create_profile_modal')
    render_logged_out
  end

  def signup
    store_register_redirect(request.referer)
  end

  # work around rails 3.0.1 bug:
  # http://techoctave.com/c7/posts/36-rails-3-0-rescue-from-routing-error-solution
  # https://rails.lighthouseapp.com/projects/8994/tickets/4444-can-no-longer-rescue_from-actioncontrollerroutingerror
  # remove once we upgrade to 3.2 and can fix this in a different way:
  # https://github.com/jorlhuda/exceptron
  def not_found
    respond_not_found
  end

protected
  def redirected_from_dashboard?
    params[:d] && (params[:d] =~ /^\/dashboard/)
  end

  def render_logged_in
    @welcome_header = :logged_in_home
    load_logged_in_home_elements
    if params[:view] == 'feed'
      feed
    elsif params[:view] == 'trending'
      trending
    elsif params[:view] == 'featured'
      featured
    elsif feature_enabled?('home.logged_in.popular_experiment')
      ab_test(:logged_in_home).in?([:popular_1, :popular_2]) ? trending : feed
    elsif feature_enabled?('home.logged_in.featured_experiment')
      ab_test(:logged_in_home_featured).in?([:featured_1, :featured_2]) ? featured : trending
    elsif feature_enabled?('home.logged_in.trending_experiment')
      trending
    else
      feed
    end
  end

  def load_logged_in_home_elements
    load_top_messages
    load_and_forget_invite_bar_request
    load_tutorial_bar if feature_enabled?(:onboarding, :tutorial_bar)
    load_collection_carousel if feature_enabled?('home.logged_in.collection_carousel')
    if params[:hn].present? || (feature_enabled?('home.logged_in.hot_or_not') && ab_test(:logged_in_home_hot_or_not).in?([:on_1, :on_2]))
      load_hot_or_not_modal
    end
  end

  def load_tutorial_bar
    steps = [TutorialBar::LikeStep.new(current_user),
             TutorialBar::CommentStep.new(current_user),
             TutorialBar::InviteStep.new(current_user)]
    bar = TutorialBar.new(steps)
    @tutorial_bar = bar unless bar.steps.all?(&:complete?)
  end

  def load_collection_carousel
    @collection_carousel = HomeCollectionCarousel.new(current_user)
  end

  def load_hot_or_not_modal
    service = HotOrNotService.new(current_user)
    if params[:hn].present? || (service.required? && !service.completed?)
      @hot_or_not_modal = HotOrNotModal.new(HotOrNotSuggestions.new(service))
    end
  end

  def feed
    load_listings_feed
    if network_listings_feed?
      suppress_new_story_polling
      set_listings_feed_flash unless request.xhr?
      if @listings_feed
        if (time = @listings_feed.end_time.to_i) > 0
          current_user.set_last_feed_refresh_time(Time.zone.at(time))
        else
          current_user.set_last_feed_refresh_time(Time.zone.now)
        end
      end
    end
    render(:feed, layout: 'home/logged_in')
  end

  def trending
    load_trending_listings
    respond_for_logged_in_with_cards(:trending, @cards, 'home/logged_in')
  end

  def featured
    per = params[:per] || Brooklyn::Application.config.home.featured.per_page
    snapshot = FeatureList.editors_picks.snapshot(params[:timestamp])
    @page_manager = listings = snapshot.listings(page: params[:page], per: per)
    params[:timestamp] ||= snapshot.timestamp
    @cards = CardCollection.new(current_user, listings)
    respond_for_logged_in_with_cards(:featured, @cards, 'home/logged_in')
  end

  def load_trending_listings
    per = params[:per] || Brooklyn::Application.config.home.trending.per_page
    snapshot = TrendingList.snapshot(params[:timestamp])
    @page_manager = listings = snapshot.listings(page: params[:page], per: per)
    params[:timestamp] ||= snapshot.timestamp
    #XXX: normalized not supported after switching to snapshots. will build that snapshot when/if needed.
    #normalize = feature_enabled?(:home, :logged_in, :trending_experiment) &&
    #              ab_test(:logged_in_home_trending_normalized).in?([:normalize_1, :normalize_2])
    @cards = CardCollection.new(current_user, listings)
  end

  def respond_for_logged_in_with_cards(action, cards, layout)
    respond_to do |format|
      format.html do
        track_usage('logged_in_homepage view')
        render(action, layout: layout)
      end
      format.json do
        results = { cards: view_context.feed_cards(cards) }
        results[:more] = next_page_path unless last_page?
        render_jsend(success: results)
      end
    end
  end

  def render_logged_out
    track_usage('homepage view')
    if params[:view] == 'trending'
      logged_out_trending
    elsif params[:view] == 'graphic'
      logged_out_graphic
    elsif feature_enabled?(:home, :logged_out, :popular_experiment) &&
          [:trending_1, :trending_2].include?(ab_test(:logged_out_home))
      logged_out_trending
    else
      logged_out_graphic
    end
  end

  def logged_out_trending
    @welcome_header = :logged_out_home
    enable_autologin
    load_trending_listings
    render(:trending, layout: 'home/logged_out')
  end

  def logged_out_graphic
    render(:index)
  end
end
