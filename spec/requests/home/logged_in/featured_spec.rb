require 'spec_helper'

describe 'LIH featured view' do
  include_context 'an authenticated session'

  let!(:listings) { FactoryGirl.create_list(:active_listing, 3) }
  let!(:like_counts) { {listings.first.id => 5, listings.second.id => 1, listings.third.id => 10 } }
  let(:snapshot) { stub('snapshot', timestamp: 123456789) }
  let(:list) { stub('editors-picks', snapshot: snapshot) }

  before do
    FeatureList.stubs(:editors_picks).returns(list)
    Listing.stubs(:like_counts).returns(like_counts)
  end

  it 'returns the first page of featured listings as HTML' do
    snapshot.expects(:listings).with(per: '1', page: nil).returns(page(listings.first, 1, 1))
    get '/', view: 'featured', per: 1
    expect(response).to be_success
    expect(response.body).to include(listings.first.title)
    expect(response.body).to_not include(listings.second.title)
    expect(response.body).to_not include(listings.third.title)
  end

  it 'returns the second page of featured listings as JSON' do
    snapshot.expects(:listings).with(per: '1', page: '2').returns(page(listings.second, 1, 1))
    xhr :get, '/', view: 'featured', per: 1, page: 2, format: :json
    expect(response).to be_jsend_success
    expect(response.jsend_data[:cards]).to have(1).card
    expect(response.jsend_data[:cards].first).to include(listings.second.title)
  end

  def page(listing, page, per)
    Kaminari::PaginatableArray.new([listing], offset: (page - 1) * per, limit: per, total_count: listings.count)
  end
end
