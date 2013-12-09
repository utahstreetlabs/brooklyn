require 'spec_helper'

describe EmailAccounts::ContactsController do
  let!(:user) { act_as_stub_user }
  let(:account) { stub_everything(:id => 1, :to_param => "1", :user => user, unregistered_contacts: []) }

  context "index" do
    before { EmailAccount.expects(:find).returns(account) }

    it "requests invites for selected contacts" do
      get :index, email_account_id: '1'
      response.should be_jsend_success
    end
  end
end
