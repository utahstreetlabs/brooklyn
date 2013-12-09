require 'spec_helper'

describe 'Create invite from Facebook facepile invite card' do
  let(:url) { '/feed/facebook_facepile_invites/requests' }

  it_behaves_like 'an anonymous request', xhr: true do
    before do
      xhr :post, url, request_id: '1234567890', to: '12345,67890', format: :json
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    it 'fails when request id param is blank' do
      xhr :post, url, to: '12345,67890'
      expect(response).to be_jsend_failure
    end

    it 'fails when to param is blank' do
      xhr :post, url, request_id: '1234567890'
      expect(response).to be_jsend_failure
    end

    it 'succeeds' do
      User.any_instance.stubs(:untargeted_invite_code).returns('deadbeef') # inviter's invite code
      xhr :post, url, {request_id: '1234567890', to: '12345,67890', source: 'invite_modal'}
      expect(response).to be_jsend_success
      expect(response.jsend_data[:creditAmount]).to be
      i = FacebookU2uInvite.find_by_fb_user_id('12345')
      expect(i).to be
      expect(i.source).to eq('invite_modal')
    end
  end
end
