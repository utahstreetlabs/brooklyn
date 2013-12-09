require 'spec_helper'

describe EmailAccountsController do
  let(:user) { act_as_stub_user }
  let(:token) { 'abcdefg' }
  let(:account) { stub_everything(:id => 1, :to_param => "1", :user => user) }

  context "create" do
    it "redirects to the contact invite page after create an email account" do
      EmailAccount.expects(:get_or_create_with_user_and_token).with(user, token).returns(account)
      post :create, { :token => token }
      response.should redirect_to(email_account_path(account))
    end
  end
end
