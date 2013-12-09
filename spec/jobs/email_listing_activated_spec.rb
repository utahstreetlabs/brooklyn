require "spec_helper"

describe EmailListingActivated do
  let(:interested_user_id) { 10 }
  let(:preferences) { stub('preferences') }
  let(:job_hash) { {} }
  let(:allow_email) { true }
  let(:interested_users) do
    [[stub('interested_user', id: interested_user_id, allow_email?: allow_email, to_job_hash: job_hash), preferences]]
  end
  let(:seller) { stub('seller', id: 30, interested_users: interested_users) }
  let(:listing_id) { 1 }
  let(:listing) { stub('listing', id: listing_id, seller: seller, seller_id: 30) }
  before { Listing.expects(:find).with(listing_id).returns(listing) }

  context "when seller blacklisted" do
    it "doesn't deliver a message" do
      EmailListingActivated.expects(:blacklisted_activators).returns([listing.seller_id])
      seller.expects(:each_interested_user).never
      EmailListingActivated.expects(:send_email).never
      EmailListingActivated.perform(listing_id)
    end
  end

  context 'when preferences successuflly fetched' do
    before { seller.expects(:each_interested_user).multiple_yields(interested_users) }

    context 'and user wants email' do
      it 'delivers a message' do
        EmailListingActivated.expects(:send_email).with(:activated, listing, job_hash)
        EmailListingActivated.perform(listing_id)
      end
    end

    context "and user doesn't want email" do
      let(:allow_email) { false }

      it "doesn't deliver a message" do
        EmailListingActivated.expects(:send_email).never
        EmailListingActivated.perform(listing_id)
      end
    end
  end


  context "when preference fetch fails" do
    let(:exception) { Exception.new("prefs fetch problemo") }
    before { seller.expects(:each_interested_user).raises(exception) }

    it "doesn't deliver a message" do
      EmailListingActivated.expects(:send_email).never
      expect { EmailListingActivated.perform(listing_id) }.to raise_exception(exception)
    end
  end
end
