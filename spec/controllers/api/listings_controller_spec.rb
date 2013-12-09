require 'spec_helper'

describe Api::ListingsController do

  let!(:user) { act_as_stub_api_consumer }
  let(:existing_listing) { stub('existing_listing', title: 'old car', description: 'This is an old description',
    seller: user, price: '300', shipping: '0', category_slug: '', slug: 'listing-slug', source_uid: '100001',
    :tags= => nil, state: 'inactive', inactive?: true) }
  let(:attributes) do
    {'title' => 'new car', 'description' => 'This is a description', 'price' => '956', 'shipping' => '5',
      'category_slug' => 'clothing', 'size_name' => nil, 'brand_name' => nil }
  end
  let(:params_hash) do
    {listing: { title: 'new car', description: 'This is a description', price: '956', shipping: '5',
      category: 'clothing', tags: {tag: ['test-tag', 'tag2', 'newtag']}, source_uid: '100001', condition: 'new'},
      id: existing_listing.slug}
  end

  context "#index" do
    let(:searcher) { stub('searcher') }
    let(:all_listings) { [stub('listing1'), stub('listing2')] }

    it "returns active and sold listings" do
      ListingSearcher.expects(:new).with(seller_id: user.id, with_sold: true).returns(searcher)
      searcher.expects(:all).returns(all_listings)
      all_listings.each { |l| l.expects(:api_hash) }
      get :index
      response.should be_success
    end

    it "only passes through whitelisted search parameters" do
      ListingSearcher.expects(:new).with(seller_id: user.id.to_s, with_sold: true, page: '2').returns(searcher)
      searcher.expects(:all).returns(all_listings)
      all_listings.each { |l| l.expects(:api_hash) }
      get :index, { seller_id: user.id, foo: :bar, baz: :quux, page: 2 }
      response.should be_success
    end
  end

  context "update" do
    it "updates existing listing fields" do
      Listing.expects(:find_by_slug!).with(existing_listing.slug).returns(existing_listing)
      existing_listing.expects(:attributes=).with(attributes)
      existing_listing.expects(:source_uid=).with('100001')
      existing_listing.expects(:condition=).with('new')
      existing_listing.expects(:save!)

      Tag.expects(:find_or_create_all_by_name).with(['test-tag', 'tag2', 'newtag'])

      put :update, params_hash
      response.should be_success
    end
  end

  context "destroy" do
    it "cancels an active listing" do
      Listing.expects(:find_by_slug!).with(existing_listing.slug).returns(existing_listing)
      existing_listing.expects(:cancel!)
      delete :destroy, id: existing_listing.slug

      response.code.should == '204'
    end

    it "returns 404 code for invalid listing" do
      Listing.expects(:find_by_slug!).with(existing_listing.slug).raises(ActiveRecord::RecordNotFound)
      get :destroy, id: existing_listing.slug

      response.code.should == '404'
    end
  end

  context "activate" do
    it "activates a listing" do
      Listing.expects(:find_by_slug!).with(existing_listing.slug).returns(existing_listing)
      existing_listing.expects(:activate!)
      post :activate, id: existing_listing.slug

      response.code.should == '204'
    end

    it "returns 404 code if cannot activate" do
      Listing.expects(:find_by_slug!).with(existing_listing.slug).raises(ActiveRecord::RecordNotFound)
      get :activate, id: existing_listing.slug

      response.code.should == '404'
    end
  end
end
