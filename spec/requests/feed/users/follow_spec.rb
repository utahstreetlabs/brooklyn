require 'spec_helper'

describe 'Follow user from feed' do
  let(:followee) { FactoryGirl.create(:registered_user) }
  let(:url) { "/feed/users/#{followee.to_param}/follow" }

  it_behaves_like 'an anonymous request', xhr: true do
    before do
      xhr :put, url, format: :json
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    it 'succeeds' do
      xhr :put, url, format: :json
      expect(response).to be_jsend_success
      expect(response.jsend_data[:follow]).to be
      expect(response.jsend_data[:followers]).to eq(1)
      expect(followee.followers).to include(viewer)
    end
  end
end
