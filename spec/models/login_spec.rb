require 'spec_helper'

describe Login do
  it 'is invalid without an email' do
    subject.should_not be_valid
    subject.errors[:email].should_not be_empty
  end

  it 'is invalid without a password' do
    subject.should_not be_valid
    subject.errors[:password].should_not be_empty
  end

  it 'is invalid without authenticated credentials' do
    subject.email = 'foo@example.com'
    subject.password = 'hi'
    User.expects(:authenticate).with(subject.email, subject.password).returns(nil)
    subject.should_not be_valid
    subject.errors[:base].should_not be_empty
  end

  it 'is valid with authenticated credentials' do
    subject.email = 'foo@example.com'
    subject.password = 'hi'
    user = mock
    User.expects(:authenticate).with(subject.email, subject.password).returns(user)
    subject.should be_valid
    subject.user.should == user
  end
end
