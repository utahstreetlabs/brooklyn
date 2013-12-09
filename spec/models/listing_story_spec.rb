require 'spec_helper'

describe ListingStory do
  describe '#complete?' do
    it 'should return false when there is no listing' do
      subject.actor = mock
      subject.photo = mock
      subject.complete?.should be_false
    end

    it 'should return false when there is no photo' do
      subject.actor = mock
      subject.listing = mock
      subject.complete?.should be_false
    end

    it 'should return true when there are actor, listing and photo' do
      subject.actor = mock
      subject.listing = mock
      subject.photo = mock
      subject.complete?.should be_true
    end
  end
end
