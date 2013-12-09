# encoding: UTF-8

shared_context 'listing scoped' do
  let(:listing) { stub_listing('MODEL 870 EXPRESS® SUPER MAG TURKEY/WATERFOWL') }
end

shared_context 'expects listing' do
  before { Listing.expects(:find_by_slug!).with(listing.slug).returns(listing) }
end
