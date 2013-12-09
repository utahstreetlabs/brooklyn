require 'spec_helper'

describe Likes::RevealLikeableLikesJob do
  let(:likeable_type) { :listing }
  let(:likeable_id) { 123 }

  describe '#perform' do
    it 'calls Pyramid::Likeable::Likes#reveal' do
      Pyramid::Likeable::Likes.expects(:reveal).with(likeable_id, likeable_type)
      Likes::RevealLikeableLikesJob.perform(likeable_type, likeable_id)
    end
  end
end
