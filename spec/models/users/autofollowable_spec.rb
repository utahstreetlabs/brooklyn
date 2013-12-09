require 'spec_helper'

describe Users::Autofollowable do
  class AutofollowingUser
    class << self
      def has_one(*args); end
    end

    include Users::Autofollowable
  end

  before { AutofollowingUser.stubs(:logger).returns(stub_everything) }

  subject do
    u = AutofollowingUser.new
    u.stubs(:id).returns(87)
    u.stubs(:logger).returns(stub_everything)
    u
  end

  describe '.add_to_autofollow_list!' do
    it 'creates the associated autofollow' do
      subject.expects(:create_autofollow!)
      subject.add_to_autofollow_list!
    end
  end

  describe '.remove_from_autofollow_list' do
    it 'nils the associated autofollow' do
      subject.expects(:autofollow=).with(nil)
      subject.remove_from_autofollow_list
    end
  end

  describe '.autofollowed?' do
    it 'returns true when the associated autofollow is not nil' do
      subject.stubs(:autofollow).returns(mock)
      subject.autofollowed?.should be_true
    end

    it 'returns false when the associated autofollow is nil' do
      subject.stubs(:autofollow).returns(nil)
      subject.autofollowed?.should be_false
    end
  end

  describe '#autofollow_list' do
    it 'returns the list of autofollowed users' do
      users = FactoryGirl.create_list(:guest_user, 5)
      autofollowed_users = users.slice(0, 3)
      autofollowed_users.each {|user| user.add_to_autofollow_list!}
      User.autofollow_list.should == autofollowed_users
    end
  end
end
