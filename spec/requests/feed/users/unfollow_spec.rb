require 'spec_helper'

describe 'Unfollow user from feed' do
  let(:followee) { FactoryGirl.create(:registered_user) }
  let(:url) { "/feed/users/#{followee.to_param}/unfollow" }

  it_behaves_like 'an anonymous request', xhr: true do
    before do
      xhr :delete, url, format: :json
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    it 'succeeds' do
      FactoryGirl.create(:follow, user: followee, follower: viewer)
      xhr :delete, url, format: :json
      expect(response).to be_jsend_success
      expect(response.jsend_data[:follow]).to be
      expect(response.jsend_data[:followers]).to eq(0)
      expect(followee.followers.reload).to be_empty
    end
  end
end
