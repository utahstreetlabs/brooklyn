require 'spec_helper'

describe OrderRating do
  describe '#failure_reason' do
    it 'converts integer code to symbol' do
      rating = FactoryGirl.create(:buyer_rating)
      rating.send(:write_attribute, :failure_reason, OrderRating::FailureReasons::NEVER_SHIPPED_CODE)
      rating.save!
      rating.reload
      rating.failure_reason.should == Order::FailureReasons::NEVER_SHIPPED
    end
  end

  describe '#failure_reason=' do
    it 'converts symbol to integer code' do
      rating = FactoryGirl.create(:buyer_rating)
      rating.failure_reason = Order::FailureReasons::NEVER_SHIPPED
      rating.save!
      rating.reload
      rating.send(:read_attribute, :failure_reason).should == OrderRating::FailureReasons::NEVER_SHIPPED_CODE
    end
  end
end
