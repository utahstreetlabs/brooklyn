require 'spec_helper'

describe PriceAlerter do
  describe '#new_message' do
    context 'when the attributes include a slug' do
      let(:attributes) { {slug: 'major-lazer'} }

      it 'builds an individual message' do
        expect(subject.new_message(attributes)).to be_a(PriceAlerter::IndividualMessage)
      end
    end

    context 'when the attributes do not include a slug' do
      let(:attributes) { {count: 5} }

      it 'builds a mass message' do
        expect(subject.new_message(attributes)).to be_a(PriceAlerter::MassMessage)
      end
    end
  end
end

describe PriceAlerter::IndividualMessage do
  it 'is not valid without a slug' do
    subject.valid?
    expect(subject.errors).to include(:slug)
  end

  it 'is not valid without a query' do
    subject.valid?
    expect(subject.errors).to include(:query)
  end

  describe '#user' do
    it 'returns the user when one exists' do
      user = FactoryGirl.create(:registered_user)
      message = PriceAlerter::IndividualMessage.new(slug: user.slug)
      expect(message.user).to eq(user)
    end

    it 'returns nil when the user does not exist' do
      message = PriceAlerter::IndividualMessage.new(slug: 'titus-andronicus')
      expect(message.user).to be_nil
    end
  end

  describe '#enqueue!' do
    it 'raises when there is no user' do
      message = PriceAlerter::IndividualMessage.new(slug: 'kurt-vile')
      expect { message.enqueue! }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises when the user is not connected to Facebook' do
      user = FactoryGirl.create(:registered_user)
      User.any_instance.stubs(:for_network).returns(nil)
      message = PriceAlerter::IndividualMessage.new(slug: user.slug)
      expect { message.enqueue! }.to raise_error(Network::NotConnected)
    end

    it 'enqueues a job when the user is connected to Facebook' do
      user = FactoryGirl.create(:registered_user)
      profile = stub('profile', id: 'deadbeef')
      User.any_instance.stubs(:for_network).returns(profile)
      Facebook::NotificationPriceAlertPostJob.expects(:enqueue).with(profile.id)
      message = PriceAlerter::IndividualMessage.new(slug: user.slug)
      message.enqueue!
    end
  end
end

describe PriceAlerter::MassMessage do
  it 'is not valid without a count' do
    subject.valid?
    expect(subject.errors).to include(:count)
  end

  it 'is not valid if the count is not an integer' do
    subject.count = 'asdf'
    subject.valid?
    expect(subject.errors).to include(:count)
  end

  it 'is not valid if the count is not greater than 0' do
    subject.count = -5
    subject.valid?
    expect(subject.errors).to include(:count)
  end
end
