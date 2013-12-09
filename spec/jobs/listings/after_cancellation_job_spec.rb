require 'spec_helper'

describe Listings::AfterCancellationJob do
  subject { Listings::AfterCancellationJob }

  let(:listing) { stub_listing 'Gold doubloon' }

  describe "#hide_likes" do
    it 'enqueues Likes::HideLikeableLikesJob' do
      Likes::HideLikeableLikesJob.expects(:enqueue).with(:listing, listing.id)
      subject.hide_likes(listing)
    end
  end
end
