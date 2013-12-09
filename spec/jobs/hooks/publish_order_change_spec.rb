require 'spec_helper'

describe Hooks::PublishOrderChange do
  describe "#perform" do
    let!(:order) {stub_everything(id: 1, api_callback?: true)}

    it "posts order to api user" do
      Order.expects(:find).with(order.id).returns(order)
      OrderHooks.expects(:fire).with(order, :created)
      Hooks::PublishOrderChange.perform(order.id, 'created')
    end

    it "fails on invalid notification type" do
      Hooks::PublishOrderChange.expects(:handle_error)
      Hooks::PublishOrderChange.perform(3, :undefined)
    end
  end
end
