require 'spec_helper'

describe Users::Balanced do
  subject { Factory.create(:registered_user) }
  let(:account) { stub('balanced-account', roles: [], uri: 'http://balancedpayments.com/accounts/deadbeef') }
  let(:marketplace) { stub('marketplace') }

  before { subject.stubs(:marketplace).returns(marketplace) }

  describe '.create_merchant!' do
    let(:identity) { Balanced::PersonMerchantIdentity.new }

    context "when the user does not already have an account" do
      before { Balanced::Account.stubs(:find).returns(nil) }

      context "and no duplicate account exists" do
        context "and the identity information is verifiable" do
          before do
            marketplace.stubs(:create_merchant).returns(account)
            subject.create_merchant!(identity)
          end
          its(:balanced_account) { should == account }
          its(:balanced_url) { should == account.uri }
        end

        context "but the identity information is not verifiable" do
          before do
            marketplace.stubs(:create_merchant).raises(Balanced::MoreInformationRequired.new({body: {}}))
          end
          it 'raises MoreInformationRequired' do
            expect { subject.create_merchant!(identity) }.to raise_error(Balanced::MoreInformationRequired)
          end
        end
      end

      context "but a duplicate account exists" do
        before do
          marketplace.stubs(:create_merchant).
            raises(Balanced::Conflict.new({body: {extras: {account_uri: account.uri}}}))
          Balanced::Account.stubs(:find).with(account.uri).returns(account)
          account.stubs(:promote_to_merchant).returns(account)
          subject.create_merchant!(identity)
        end
        its(:balanced_account) { should == account }
        its(:balanced_url) { should == account.uri }
      end
    end

    context "when the user already has an account" do
      before do
        subject.balanced_url = account.uri
        subject.save!
        Balanced::Account.stubs(:find).with(account.uri).returns(account)
      end

      context "without the merchant role" do
        before do
          account.expects(:promote_to_merchant).returns(account)
          subject.create_merchant!(identity)
        end
        its(:balanced_account) { should == account }
      end

      context "with the merchant role" do
        before do
          account.roles << 'merchant'
          account.expects(:create_merchant).never
          account.expects(:promote_to_merchant).never
          subject.create_merchant!(identity)
        end
        its(:balanced_account) { should == account }
      end
    end
  end

  describe '.create_buyer' do
    let(:card) { stub('card', uri: 'http://balancedpayments.com/cards/deadbeef') }

    context "when the user does not already have an account" do
      before { Balanced::Account.stubs(:find).returns(nil) }

      context "and no duplicate account exists" do
        before do
          marketplace.stubs(:create_buyer).returns(account)
          subject.create_buyer!(card)
        end
        its(:balanced_account) { should == account }
        its(:balanced_url) { should == account.uri }
      end

      context "but a duplicate account exists" do
        before do
          marketplace.stubs(:create_buyer).
            raises(Balanced::Conflict.new({body: {extras: {account_uri: account.uri}}}))
          Balanced::Account.stubs(:find).with(account.uri).returns(account)
          account.stubs(:add_card).with(card.uri).returns(account)
          subject.create_buyer!(card)
        end
        its(:balanced_account) { should == account }
        its(:balanced_url) { should == account.uri }
      end
    end

    context "when the user already has an account" do
      before do
        subject.balanced_url = account.uri
        subject.save!
        Balanced::Account.stubs(:find).with(account.uri).returns(account)
        account.expects(:add_card).with(card.uri).returns(account)
        subject.create_buyer!(card)
      end
      its(:balanced_account) { should == account }
    end
  end
end
