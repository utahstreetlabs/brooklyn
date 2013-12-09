require 'spec_helper'

describe Api::Listings::ActiveController do
  let!(:user) { act_as_stub_api_consumer }

  context "#index" do
    let(:searcher) { stub('searcher') }
    let(:active_listings) { [stub('active_listing1'), stub('active_listing2')] }

    it "returns active listings" do
      ListingSearcher.expects(:new).with(seller_id: user.id, with_sold: false).returns(searcher)
      searcher.expects(:all).returns(active_listings)
      active_listings.each { |l| l.expects(:api_hash) }
      get :index
      response.should be_success
    end

    it "only passes through whitelisted search parameters" do
      ListingSearcher.expects(:new).with(seller_id: user.id.to_s, with_sold: false, page: '2').returns(searcher)
      searcher.expects(:all).returns(active_listings)
      active_listings.each { |l| l.expects(:api_hash) }
      get :index, { seller_id: user.id, foo: :bar, baz: :quux, page: 2 }
      response.should be_success
    end
  end
end
