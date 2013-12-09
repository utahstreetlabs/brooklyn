require 'spec_helper'

describe PostalAddress do
  context "#cancel_order!" do
    subject { FactoryGirl.create(:shipping_address) }
    let!(:order) { FactoryGirl.create(:pending_order, shipping_address: subject) }
    let!(:cancelled_order) { CancelledOrder.create_from_order(order, {}) }

    before { subject.cancel_order! }
    its(:order) { should_not be }
    its(:cancelled_order) { should == cancelled_order }
  end
end
