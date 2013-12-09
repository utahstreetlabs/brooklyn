require 'spec_helper'

describe Listings::AfterDeactivationJob do
  subject { Listings::AfterDeactivationJob }

  let(:listing) { stub_listing 'Bloody axe' }

  describe "#hide_likes" do
    it 'enqueues Likes::HideLikeableLikesJob' do
      Likes::HideLikeableLikesJob.expects(:enqueue).with(:listing, listing.id)
      subject.hide_likes(listing)
    end
  end
end
