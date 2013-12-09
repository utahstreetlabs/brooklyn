require 'spec_helper'

describe 'LIH trending view' do
  include_context 'an authenticated session'

  let!(:listings) { FactoryGirl.create_list(:active_listing, 3) }
  let!(:now) { Time.zone.now }
  let!(:snapshot) { stub('snapshot', timestamp: now.to_i) }


  context 'for the first page of listings' do
    before do
      TrendingList.stubs(:snapshot).returns(snapshot)
      snapshot.expects(:listings).with(per: '1', page: nil).returns(page(listings.first, 1, 1))
    end

    it 'returns the listings as HTML' do
      get '/', view: 'trending', per: 1
      expect(response).to be_success
      expect(response.body).to include(listings.first.title)
      expect(response.body).to_not include(listings.second.title)
      expect(response.body).to_not include(listings.third.title)
    end

    it 'includes a timestamp in subsequent urls' do
      Timecop.freeze(now) do
        get '/', view: 'trending', per: 1
        doc = Capybara::Node::Simple.new(response.body)
        expect(doc).to have_css("[data-more-url*='timestamp=#{now.to_i}']")
      end
    end
  end

  context 'for the second page of listings' do
    before do
      TrendingList.stubs(:snapshot).returns(snapshot)
      snapshot.expects(:listings).with(per: '1', page: '2').returns(page(listings.second, 2, 1))
    end

    it 'returns the listings as JSON' do
      xhr :get, '/', view: 'trending', per: 1, page: 2, format: :json
      expect(response).to be_jsend_success
      expect(response.jsend_data[:cards]).to have(1).card
      expect(response.jsend_data[:cards].first).to include(listings.second.title)
    end

    it 'uses the timestamp from params if there is one' do
      now = Time.zone.now
      Timecop.travel(now + 2.minutes) do
        xhr :get, '/', view: 'trending', per: 1, page: 2, format: :json, timestamp: now.to_i
        expect(response.jsend_data[:more]).to match("timestamp=#{now.to_i}")
      end
    end
  end

  # this test exists because we were having problems with page 2 being requested repeatedly
  it 'returns the third page of trending listings as JSON' do
    TrendingList.stubs(:snapshot).returns(snapshot)
    snapshot.expects(:listings).with(per: '1', page: '3').returns(page(listings.third, 3, 1))
    xhr :get, '/', view: 'trending', per: 1, page: 3, format: :json
    expect(response).to be_jsend_success
    expect(response.jsend_data[:cards]).to have(1).card
    expect(response.jsend_data[:cards].first).to include(listings.third.title)
  end

  def page(listing, page, per)
    Kaminari::PaginatableArray.new([listing], offset: (page - 1) * per, limit: per, total_count: listings.count)
  end
end
