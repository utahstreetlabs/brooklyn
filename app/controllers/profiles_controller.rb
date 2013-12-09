class ProfilesController < ApplicationController
  include Controllers::InfinitelyScrollable
  include Controllers::ProfileScoped

  skip_requiring_login_only

  load_profile_user
  require_registered_profile_user
  customize_action_event variables: [:profile_user]

  def respond_with_objects(objects)
    @results = objects.any?? CardCollection.new(viewer, objects, listings_per_card: tag_card_listing_count) : objects
    respond_to do |format|
      format.html
      format.json do
        results = { cards: view_context.feed_cards(@results) }
        results[:more] = next_page_path unless last_page?
        render_jsend(success: results)
      end
    end
  end

  def show
    options = params.merge(seller_id: profile_user.id, includes: [:size, {seller: :person}], with_sold: true)
    @page_manager = searcher = ListingSearcher.new(options)
    track_profile_view(profile_tabs: 'listings')
    respond_with_objects(searcher.error ? [] : searcher.all)
  end

  def liked
    @page_manager = likes = profile_user.liked(tab_params.merge(listing: {includes: [:size, {seller: :person}]}))
    track_profile_view(profile_tabs: 'likes')
    respond_with_objects(likes)
  end

  def followers
    users = profile_user.registered_followers(tab_params.merge(order: :reverse_chron))
    @cards = UserCards.new(users, current_user, profile_user.registered_follows(tab_params))
    track_profile_view(profile_tabs: 'followers')
  end

  protected
    def tag_card_listing_count
      Brooklyn::Application.config.tags.cards.profile_listing_count
    end
end
