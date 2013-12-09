class Profiles::FollowingController < ApplicationController
  include Controllers::InfinitelyScrollable
  include Controllers::ProfileScoped

  skip_requiring_login_only

  load_profile_user
  require_registered_profile_user
  customize_action_event variables: [:profile_user]

  def collections
    collections = profile_user.unowned_collection_follows.map(&:collection)
    @cards = CollectionCards.new(current_user, collections)
    track_profile_view(profile_tabs: 'following-collections')
    render(layout: 'profiles')
  end

  def people
    users = profile_user.registered_followees(tab_params.merge(order: :reverse_chron))
    @cards = UserCards.new(users, current_user, profile_user.registered_followings(tab_params))
    track_profile_view(profile_tabs: 'following-people')
    render(layout: 'profiles')
  end
end
