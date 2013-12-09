require 'spec_helper'
require 'timecop'

describe Shipments::ExpireShippingLabelsJob do
  # this is an integration test, since mocking wouldn't test anything useful
  it 'finds and expires listings' do
    label = FactoryGirl.create(:shipping_label)
    Timecop.travel(label.expires_in + 1.day) do
      Shipments::ExpireShippingLabelsJob.perform
    end
    label.reload
    label.should be_expired
  end
end
