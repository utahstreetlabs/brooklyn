require 'spec_helper'

describe Likes::HideLikeableLikesJob do
  let(:likeable_type) { :listing }
  let(:likeable_id) { 123 }

  describe '#perform' do
    it 'calls Pyramid::Likeable::Likes#hide' do
      Pyramid::Likeable::Likes.expects(:hide).with(likeable_id, likeable_type)
      Likes::HideLikeableLikesJob.perform(likeable_type, likeable_id)
    end
  end
end
