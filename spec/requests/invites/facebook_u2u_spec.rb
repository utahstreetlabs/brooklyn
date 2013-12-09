require 'spec_helper'

describe 'Facebook U2U invites' do
  it_behaves_like 'an anonymous request', xhr: true do
    before do
      xhr :post, '/invites/facebook_u2u', request_id: '1234567890', to: '12345,67890', format: :json
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    it 'fails when request id param is blank' do
      xhr :post, '/invites/facebook_u2u', to: '12345,67890'
      expect(response).to be_jsend_failure
    end

    it 'fails when to param is blank' do
      xhr :post, '/invites/facebook_u2u', request_id: '1234567890'
      expect(response).to be_jsend_failure
    end

    it 'succeeds' do
      referer = '/'
      User.any_instance.stubs(:untargeted_invite_code).returns('deadbeef') # inviter's invite code
      xhr :post, '/invites/facebook_u2u', {request_id: '1234567890', to: '12345,67890', source: 'invite_modal'},
          'HTTP_REFERER' => referer
      expect(response).to be_jsend_success
      # XXX: until we figure out why FB.ui explodes after calling our callback, just reload the page rather than
      # re-rendering the bar. the referring controller is responsible for removing the request id from the session.
#      expect(response.jsend_data[:bar]).to be
      expect(response.jsend_data[:redirect]).to eq(referer)
      i = FacebookU2uInvite.find_by_fb_user_id('12345')
      expect(i).to be
      expect(i.source).to eq('invite_modal')
    end
  end
end
