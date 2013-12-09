require 'spec_helper'

describe ListingOffer do
  describe 'validation' do
    subject { FactoryGirl.build(:listing_offer) }

    it 'fails when amount is blank' do
      subject.amount = nil
      expect(subject).to_not be_valid
    end

    it 'fails when amount is not a number' do
      subject.amount = 'lots!'
      expect(subject).to_not be_valid
    end

    it 'fails when amount is not positive' do
      subject.amount = 0
      expect(subject).to_not be_valid
    end

    it 'fails when duration is blank' do
      subject.duration = nil
      expect(subject).to_not be_valid
    end

    it 'fails when duration is not a number' do
      subject.duration = 'never'
      expect(subject).to_not be_valid
    end

    it 'fails when duration is not an integer' do
      subject.duration = 3.14
      expect(subject).to_not be_valid
    end

    it 'fails when duration is not positive' do
      subject.duration = 0
      expect(subject).to_not be_valid
    end
  end

  describe 'after create' do
    subject { FactoryGirl.build(:listing_offer) }

    it 'enqueues ListingOffers::AfterCreationJob' do
      ListingOffers::AfterCreationJob.expects(:enqueue).with(is_a(Integer))
      subject.save!
    end
  end
end
