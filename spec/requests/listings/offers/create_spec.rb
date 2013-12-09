require 'spec_helper'

describe 'Make offer for listing' do
  let(:listing) { FactoryGirl.create(:active_listing) }
  let(:url) { "/listings/#{listing.to_param}/offers" }

  it_behaves_like 'an anonymous request', xhr: true do
    before do
      xhr :post, url, format: :json
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    it 'succeeds' do
      xhr :post, url, offer: {amount: 5.00, duration: 2.days}, format: :json
      expect(response).to be_jsend_success
      expect(response.jsend_data[:followupModal]).to be
      expect(response.jsend_data[:replace]).to be
      expect(listing.offers).to have(1).offer
    end

    it 'fails with invalid inputs' do
      xhr :post, url, offer: {}, format: :json
      expect(response).to be_jsend_failure
      expect(response.jsend_data[:modal]).to be
      expect(response.jsend_data[:followupModal]).to_not be
      expect(response.jsend_data[:replace]).to_not be
      expect(listing.offers).to be_empty
    end
  end
end
