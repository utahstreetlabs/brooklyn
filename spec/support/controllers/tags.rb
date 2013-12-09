shared_context 'tag scoped' do
  let(:tag) { stub_tag('comics') }
  let(:featurable) { tag }
end

shared_context 'expects tag' do
  before { Tag.expects(:find).with(tag.id.to_s).returns(tag) }
end
