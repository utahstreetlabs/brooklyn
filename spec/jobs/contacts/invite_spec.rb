require 'spec_helper'

describe Contacts::Invite do
  let(:user) { stub_everything('user', id: 1) }
  let(:account) { stub_everything('email_account', id: 1, user: user) }
  let(:contact1) { stub_everything('contact1', id: 1, email_account_id: account.id) }
  let(:contact2) { stub_everything('contact2', id: 2, email_account_id: account.id) }
  let(:contacts) { [contact1, contact2] }

  before do
    Contact.expects(:find_by_ids_with_email_accounts).returns(contacts)
  end

  it "invites contacts by id" do
    contact1.expects(:invite)
    contact2.expects(:invite)
    Contacts::Invite.perform(user.id, [contact1.id, contact2.id])
  end
end
