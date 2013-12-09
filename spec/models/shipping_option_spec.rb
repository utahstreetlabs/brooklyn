require 'spec_helper'

describe ShippingOption do
  describe 'with valid attributes' do
    subject { FactoryGirl.build(:shipping_option) }
    it { should be_valid }
  end

  describe 'without a code' do
    subject { FactoryGirl.build(:shipping_option, code: nil) }
    it { should_not be_valid }
  end

  describe 'with a blank code' do
    subject { FactoryGirl.build(:shipping_option, code: ' ') }
    it { should_not be_valid }
  end

  describe 'with a code that is too long' do
    subject { FactoryGirl.build(:shipping_option, code: ('a'*50)) }
    it { should_not be_valid }
  end

  describe 'with a code that does not correspond to a configured option' do
    subject { FactoryGirl.build(:shipping_option, code: 'howdy doody') }
    it { should_not be_valid }
  end

  describe 'without a rate' do
    subject { FactoryGirl.build(:shipping_option, rate: nil) }
    it { should_not be_valid }
  end

  describe 'with a blank rate' do
    subject { FactoryGirl.build(:shipping_option, rate: ' ') }
    it { should_not be_valid }
  end

  describe 'with a non-numerical rate' do
    subject { FactoryGirl.build(:shipping_option, rate: 'foobar') }
    it { should_not be_valid }
  end

  describe 'with a negative rate' do
    subject { FactoryGirl.build(:shipping_option, rate: -25.to_d) }
    it { should_not be_valid }
  end
end
