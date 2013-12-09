require 'spec_helper'

describe Contacts::Import do
  let(:user) { stub_everything('user', id: 1) }
  let(:account) { stub_everything('email_account', id: 1, user: user) }

  before do
    EmailAccount.expects(:find).with(account.id).returns(account)
  end

  it "tracks usage" do
    Brooklyn::UsageTracker.expects(:async_track).with(:address_book_import, has_entries(user: user))
    Contacts::Import.perform(account.id)
  end
end
