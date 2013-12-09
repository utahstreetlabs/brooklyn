shared_context 'user does not have a merchant account' do
  before { user.stubs(:balanced_merchant?).returns(false) }
end

shared_context 'user has a merchant account' do
  before { user.stubs(:balanced_merchant?).returns(true) }
end

shared_context 'user does not have deposit accounts' do
  before { user.stubs(:deposit_accounts).returns([]) }
end

shared_context 'user has deposit accounts' do
  before { user.stubs(:deposit_accounts).returns([mock]) }
end

shared_context 'user has proceeds awaiting settlement' do
  before { user.stubs(:proceeds_awaiting_settlement).returns(0) }
end

shared_examples 'with a merchant account' do
  include_context 'user has a merchant account'

  it "redirects to accounts page" do
    response.should redirect_to(settings_seller_accounts_path)
  end
end

shared_examples 'without a merchant account' do
  include_context 'user does not have a merchant account'

  it "redirects to identity page" do
    response.should redirect_to(settings_seller_identity_path)
  end
end
