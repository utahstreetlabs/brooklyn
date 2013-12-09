require 'spec_helper'

describe 'LIH feed view' do
  include_context 'an authenticated session'

  let!(:listings) { FactoryGirl.create_list(:active_listing, 3) }

  it 'returns the first page of feed listings as HTML' do
    actor = FactoryGirl.create(:registered_user)
    story = stub_listing_story(type: :listing_liked, listing: listings.first, actor: actor)
    StoryFeeds::CardFeed.stubs(:find_slice).returns([story])
    get '/', view: 'feed', limit: 1
    expect(response).to be_success
    expect(response.body).to include(listings.first.title)
    expect(response.body).to_not include(listings.second.title)
    expect(response.body).to_not include(listings.third.title)
  end
end
