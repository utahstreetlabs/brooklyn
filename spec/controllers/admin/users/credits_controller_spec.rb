require 'spec_helper'

describe Admin::Users::CreditsController do
  let(:user) { stub_user 'Marvin Gaye' }
  before do
    act_as_stub_user
    can(:grant, Credit)
    User.stubs(:find).with(user.id.to_s).returns(user)
  end

  describe '#create' do
    it 'grants a credit to the user' do
      Time.freeze do
        amount = 1.00.to_d
        credit = stub('credit')
        Credit.expects(:new).
          with(amount: amount, expires_at: Time.zone.now + Credit.default_duration).
          returns(credit)
        credit.expects(:user=).with(user)
        credit.expects(:save).returns(true)
        post :create, user_id: user.id.to_s, credit: {amount: amount.to_s}
        response.should be_jsend_success
        response.jsend_data['message'].should be
        response.jsend_data['redirect'].should be
      end
    end

    it 'returns failure when the amount is bogus' do
      Time.freeze do
        amount = -1.00.to_d
        credit = stub('credit')
        Credit.expects(:new).with(amount: amount, expires_at: Time.zone.now + Credit.default_duration).returns(credit)
        credit.expects(:user=).with(user)
        credit.expects(:save).returns(false)
        post :create, user_id: user.id.to_s, credit: {amount: amount.to_s}
        response.should be_jsend_success
        response.jsend_data['modal'].should be
      end
    end
  end
end
