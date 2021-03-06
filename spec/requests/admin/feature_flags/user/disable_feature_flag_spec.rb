require 'spec_helper'

describe 'Disable user feature flag' do
  let(:flag) { FactoryGirl.create(:feature_flag, enabled: true) }
  let(:url) { "/admin/feature_flags/#{flag.id}/user" }

  it_behaves_like 'an anonymous request', xhr: true do
    before do
      xhr :delete, url, format: :json
    end
  end

  it_behaves_like 'a non-admin request', xhr: true do
    before do
      xhr :delete, url, format: :json
    end
  end

  context "when logged in as an admin" do
    include_context 'an authenticated session', admin: true

    it 'succeeds' do
      xhr :delete, url
      expect(response).to be_jsend_success
      expect(response.jsend_data[:refresh]).to match(/post/) # enable url
    end
  end
end
