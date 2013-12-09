require 'spec_helper'

describe Listings::AfterRelistJob do
  let(:listing) { stub_listing 'Can of tennis balls' }

  subject { Listings::AfterRelistJob }

  describe "#reveal_likes" do
    it 'enqueues Likes::RevealLikeableLikesJob' do
      Likes::RevealLikeableLikesJob.expects(:enqueue).with(:listing, listing.id)
      subject.reveal_likes(listing)
    end
  end
end
