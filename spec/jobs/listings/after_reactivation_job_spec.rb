require 'spec_helper'

describe Listings::AfterReactivationJob do
  let(:listing) { stub_listing 'Can of tennis balls' }

  subject { Listings::AfterReactivationJob }

  describe "#reveal_likes" do
    it 'enqueues Likes::RevealLikeableLikesJob' do
      Likes::RevealLikeableLikesJob.expects(:enqueue).with(:listing, listing.id)
      subject.reveal_likes(listing)
    end
  end
end
