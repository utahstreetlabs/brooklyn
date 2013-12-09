require 'spec_helper'

describe Want do
  describe 'validation' do
    subject { FactoryGirl.build(:want) }

    it 'fails when the max price is not present' do
      subject.max_price = nil
      expect(subject).to_not be_valid
    end

    it 'fails when the max price is too low' do
      subject.max_price = -5
      expect(subject).to_not be_valid
    end

    it 'succeeds when max price is positive' do
      expect(subject).to be_valid
    end

    it 'fails when the condition is not in the specified list' do
      subject.condition = 'foobar'
      expect(subject).to_not be_valid
    end
  end

  describe 'after create' do
    it 'tracks an event' do
      want = FactoryGirl.build(:want)
      want.expects(:track_usage).with(is_a(Events::WantItem))
      want.save!
    end
  end
end
