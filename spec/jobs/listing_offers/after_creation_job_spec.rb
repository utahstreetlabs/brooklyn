require 'spec_helper'

describe ListingOffers::AfterCreationJob do
  subject { ListingOffers::AfterCreationJob }
  let(:offer) { FactoryGirl.create(:listing_offer) }

  describe '#send_email_to_admin' do
    it 'sends email' do
      subject.expects(:send_email).with(:created_for_admin, offer)
      subject.send_email_to_admin(offer)
    end
  end

  describe '#update_mixpanel' do
    it "tracks usage" do
      subject.expects(:track_usage).with(is_a(Events::ListingOfferCreate))
      subject.update_mixpanel(offer)
    end
  end
end
