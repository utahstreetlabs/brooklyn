shared_context 'category scoped' do
  let(:category) { stub_category('shotguns') }
  let(:featurable) { category }
end

shared_context 'expects category' do
  before { Category.expects(:find_by_slug!).with(category.slug).returns(category) }
end
