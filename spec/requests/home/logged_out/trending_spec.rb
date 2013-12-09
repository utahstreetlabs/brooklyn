require 'spec_helper'

describe 'LOH trending view' do
  let!(:listings) { FactoryGirl.create_list(:active_listing, 3) }
  let!(:snapshot) { stub('snapshot', timestamp: 123456789) }

  it 'returns the first page of trending listings from a snapshot' do
    TrendingList.stubs(:snapshot).returns(snapshot)
    snapshot.expects(:listings).with(per: '1', page: nil).returns(page(listings.first, 1, 1))
    get '/', view: 'trending', per: 1
    expect(response).to be_success
    expect(response.body).to include(listings.first.title)
    expect(response.body).to_not include(listings.second.title)
    expect(response.body).to_not include(listings.third.title)
  end

  def page(listing, page, per)
    Kaminari::PaginatableArray.new([listing], offset: (page - 1) * per, limit: per, total_count: listings.count)
  end
end
