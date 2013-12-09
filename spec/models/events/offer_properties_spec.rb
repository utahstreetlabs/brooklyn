require 'spec_helper'

describe Events::OfferProperties do
  class Events::OfferPropertiesImpl; include Events::OfferProperties; end
  subject { Events::OfferPropertiesImpl }

  describe '#offer_properties' do
    let(:offer_id) { 2 }
    let(:offer) { stub_offer('offer') }
    before { Offer.expects(:find).returns(offer) }
    it 'should return standard offer properties for mixpanel events' do
      p = subject.offer_properties(offer_id)
      p.should include(offer_name: offer.name, ab_test_id: offer.ab_tag, offer_amount: offer.amount,
               minimum_purchase: offer.minimum_purchase, credit_duration: offer.duration,
               offer_expires_at: offer.expires_at, eligible_users: :all)
      #XXX: track sellers, tags, first time purchase, zero credit balance
    end
  end
end
