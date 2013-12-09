require 'spec_helper'

describe DepositAccount do
  describe '.create_balanced_account!' do
    let(:balanced_bank_account) do
      stub('bank-account', uri: 'http://balancedpayments.com/bank-accounts/deadbeef', last_four: '0987')
    end
    let(:balanced_user_account) do
      stub('user-account', uri:'http://balancedpayments.com/bank-accounts/cafebebe' )
    end
    let(:account) do
      account = FactoryGirl.build(:deposit_account)
      account.skip_create = false
      account.stubs(:new_balanced_account).returns(balanced_bank_account)
      account.user.stubs(:balanced_account).returns(balanced_user_account)
      account
    end

    it "happily" do
      balanced_bank_account.stubs(:save).returns(balanced_bank_account)
      balanced_user_account.stubs(:add_bank_account)
      account.stubs(:balanced_account).returns(balanced_bank_account)
      account.send(:create_balanced_account!).should == balanced_bank_account
      account.balanced_url.should == balanced_bank_account.uri
      account.last_four.should == balanced_bank_account.last_four
    end

    it "raises UnidentifiedBank when the routing number can't be matched to an actual bank" do
      balanced_bank_account.stubs(:save).
        raises(Balanced::BadRequest.new(body: {category_code: 'invalid-routing-number'}))
    end
  end
end
