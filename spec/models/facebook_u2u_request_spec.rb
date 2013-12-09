require 'spec_helper'

describe FacebookU2uRequest do
  describe '#create_invite_request!' do
    it 'creates the request and associated invites' do
      user = FactoryGirl.create(:registered_user)
      user.expects(:mark_inviter!)
      user.stubs(:untargeted_invite_code).returns('deadbeef')
      request_id = '1234567890'
      fb_invitee_ids = ['01234', '56789']
      source = 'aaa'
      request = FacebookU2uRequest.create_invite_request!(user, request_id, fb_invitee_ids, source: source)
      request.reload
      request.user.should == user
      request.fb_request_id.should == request_id
      request.invites.should have(2).elements
      request.invites.each do |invite|
        invite.fb_user_id.should be_in(fb_invitee_ids)
        invite.invite_code.should == user.untargeted_invite_code
        invite.source.should == source
      end
    end
  end
end
