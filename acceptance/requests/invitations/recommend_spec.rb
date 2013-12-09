require './acceptance/spec_helper'

feature 'Invite a friend via a recommendation', js: true do
  feature_flag('listings.recommend', true)

  before do
    login_as "starbuck@galactica.mil"
    given_listing
  end

  scenario 'using a custom modal' do
    pending "Recommend modal has been removed.  Unpend if it comes back."
    visit_active_listing
    open_recommend_modal
    recommend_modal_should_open_with_a_multi_friend_selector
  end

  def visit_active_listing
    listing = given_listing
    visit listing_path(listing)
  end

  def open_recommend_modal
    open_modal(recommend_modal_id)
  end

  def recommend_modal_should_open_with_a_multi_friend_selector
    within_modal(recommend_modal_id) do
      page.should have_selector('[data-role=multi-friend-selector]')
    end
  end

  def recommend_modal_id
    'recommend-listing'
  end
end
