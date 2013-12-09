class Profiles::CollectionsController < ApplicationController
  include Controllers::InfinitelyScrollable
  include Controllers::ProfileScoped

  skip_requiring_login_only
  load_profile_user
  require_registered_profile_user
  customize_action_event variables: [:profile_user]

  def index
    collections = profile_user.collections.sort { |a, b| b.created_at <=> a.created_at }
    @cards = CollectionCards.new(current_user, collections, owner: @profile_user)
    track_profile_view(profile_tabs: 'collections')
    render(layout: 'profiles')
  end

  def show
    @collection = profile_user.collections.includes(:user).find_by_slug!(params[:id])
    @page_manager = items = @collection.find_visible_listings(params.slice(:page, :per))
    @cards = CardCollection.new(current_user, items, listings_per_card: Collection.items_per_page,
                                collection: @collection)
    track_usage(Events::CollectionView.new(current_user, @collection))
    respond_to do |format|
      format.json do
        results = {
          cards: view_context.feed_cards(@cards)
        }
        results[:more] = next_page_path unless last_page?
        render_jsend(success: results)
      end
      format.html
    end
  end
end
