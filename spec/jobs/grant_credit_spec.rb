require "spec_helper"

describe GrantCredit do
  let(:user) { stub('user', id: 1) }
  let(:type) { :signup }

  it "should grant a credit" do
    User.stubs(:find).with(user.id).returns(user)
    attrs = {foo: :bar}
    Credit.expects(:grant_if_eligible!).with(user, type, attrs)
    GrantCredit.perform(user.id, type, attrs)
  end
end
