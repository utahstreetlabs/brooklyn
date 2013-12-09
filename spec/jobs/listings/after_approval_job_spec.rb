require 'spec_helper'

describe Listings::AfterApprovalJob do
  let(:seller) { stub_user 'Crackity Jonez' }
  let(:listing) do
    stub_listing 'Antique pick axe mining tool coal, silver', seller: seller, approved?: true, disapproved?: false
  end

  subject { Listings::AfterApprovalJob }

  describe "#inject_activated_story" do
    it 'injects the stories, with tag followers for ylf' do
      subject.expects(:inject_listing_story).with(:listing_activated, seller.id, listing, {},
        has_entries(feed: [:ev, :ylf]))
      subject.inject_activated_story(listing)
    end
  end
end
