require 'spec_helper'

describe Admin::Users::AdminController do
  let(:user) { stub_user 'Jimi Hendrix' }
  before do
    act_as_stub_user
    can(:grant_admin, user)
    User.stubs(:find).with(user.id.to_s).returns(user)
  end

  describe '#update' do
    it 'grants admin access to the user' do
      user.expects(:update_attribute).with(:admin, true)
      put :update, user_id: user.id.to_s
      response.should be_jsend_success
      response.jsend_data['alert'].should be
      response.jsend_data['userInfo'].should be
    end
  end

  describe '#destroy' do
    it 'revokes admin access from the user' do
      user.expects(:update_attribute).with(:admin, false)
      delete :destroy, user_id: user.id.to_s
      response.should be_jsend_success
      response.jsend_data['alert'].should be
      response.jsend_data['userInfo'].should be
    end
  end
end
