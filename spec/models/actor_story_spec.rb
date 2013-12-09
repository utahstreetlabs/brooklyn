require 'spec_helper'

describe ActorStory do
  before do
    subject.stubs(:actor).returns(stub('actor'))
  end
  describe '#complete?' do
    it 'should return false when there are no listings' do
      subject.listing_ids = nil
      subject.complete?.should be_false
      subject.listing_ids = []
      subject.complete?.should be_false
    end

    it 'should return true when there are is a listing' do
      subject.listing_ids = [1]
      subject.complete?.should be_true
    end
  end
end
