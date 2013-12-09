require 'spec_helper'

describe ListingOfferMailer do
  let(:offer) { FactoryGirl.create(:listing_offer) }

  it "builds a created_for_admin message" do
    expect { ListingOfferMailer.created_for_admin(offer) }.to_not raise_error
  end
end
