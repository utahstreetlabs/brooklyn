require 'spec_helper'

describe 'Home page invite bar' do
  it_behaves_like 'an anonymous request', xhr: true do
    before do
      xhr :delete, '/home/invite-bar', format: :json
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    it 'succeeds' do
      xhr :delete, '/home/invite-bar'
      expect(response).to be_jsend_success
      expect(session[:ibc]).to be_true
    end
  end
end
