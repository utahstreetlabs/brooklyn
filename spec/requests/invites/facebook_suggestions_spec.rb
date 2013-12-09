require 'spec_helper'

describe 'Facebook invite suggestions' do
  it_behaves_like 'an anonymous request', xhr: true do
    before do
      xhr :get, '/invites/facebook_suggestions', format: :json
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'
    let(:suggestion) { stub_network_profile('ee cummings', :facebook, name: 'ee cummings') }

    it 'succeeds' do
      User.any_instance.stubs(:invite_suggestions).returns([suggestion])
      xhr :get, '/invites/facebook_suggestions', format: :json
      expect(response).to be_jsend_success
    end
  end
end
