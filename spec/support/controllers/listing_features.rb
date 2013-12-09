shared_context 'listing_feature scoped' do
  let(:feature) { stub_listing_feature }
end

# requires featurable to have been defined externally
shared_context 'expects listing_feature' do
  before { featurable.expects(:find_feature).with(feature.id.to_s).returns(feature) }
end
