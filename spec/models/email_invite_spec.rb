require 'spec_helper'

describe EmailInvite do
  it 'requires to to be present' do
    subject.should_not be_valid
    subject.errors[:to].should have(1).message
  end

  it 'requires addresses to be valid' do
    subject.to = 'foo'
    subject.should_not be_valid
    subject.errors[:to].should have(1).message
  end

  it 'requires a limited number of addresses' do
    subject.to = (1..EmailInvite.max_recipients+1).map {'starbuck@galactica.mil'}.join(' ')
    subject.should_not be_valid
    subject.errors[:to].should have(1).message
  end

  it 'validates successfully' do
    subject.to = 'starbuck@galactica.mil'
    subject.should be_valid
  end

  describe '#to=' do
    it 'adds addresses' do
      subject.to = 'starbuck@galactica.mil'
      subject.addresses.should == ['starbuck@galactica.mil']
    end

    it 'splits addresses on whitespace' do
      subject.to = 'starbuck@galactica.mil apollo@galactica.mil'
      subject.addresses.should include('starbuck@galactica.mil', 'apollo@galactica.mil')
    end

    it 'splits addresses on comma' do
      subject.to = 'starbuck@galactica.mil,apollo@galactica.mil'
      subject.addresses.should include('starbuck@galactica.mil', 'apollo@galactica.mil')
    end

    it 'splits addresses on comma and whitespace' do
      subject.to = 'starbuck@galactica.mil,  apollo@galactica.mil'
      subject.addresses.should include('starbuck@galactica.mil', 'apollo@galactica.mil')
    end
  end
end
