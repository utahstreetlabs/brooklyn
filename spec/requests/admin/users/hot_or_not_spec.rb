require 'spec_helper'

describe 'View hot or not suggestions' do
  let(:user) { FactoryGirl.create(:registered_user) }
  let(:url) { "/admin/users/#{user.id}/hot_or_not" }

  it_behaves_like 'an anonymous request', xhr: true do
    before do
      xhr :get, url, format: :json
    end
  end

  it_behaves_like 'a non-admin request', xhr: true do
    before do
      xhr :get, url, format: :json
    end
  end

  context "when logged in as an admin" do
    include_context 'an authenticated session', admin: true
    let(:listing) { FactoryGirl.create(:active_listing) }

    it 'succeeds' do
      User.any_instance.expects(:hot_or_not_suggestions).returns([listing])
      xhr :get, url, format: :json
      expect(response).to be_jsend_success
      expect(response.jsend_data[:modal]).to match(/#{listing.title}/)
    end
  end
end
