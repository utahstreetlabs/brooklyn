require 'spec_helper'

describe Admin::AnnotationsController do
  describe "#create" do
    before do
      act_as_stub_user
    end

    it "creates a new annotation on a user" do
      user = stub_user('Boba Fett')
      User.expects(:find).with(user.id.to_s).returns(user)
      Annotation.any_instance.expects(:save).returns(true)
      Annotation.any_instance.expects(:annotatable=).with(user)
      post :create, user_id: user.id, annotation: {annotatable_type: 'User', url: 'hams'}
      response.should redirect_to(admin_user_path(user.id))
    end

    it "creates a new annotation on an order" do
      order = stub_order(stub_listing("Fett's Vette"))
      Order.expects(:find).with(order.id.to_s).returns(order)
      Annotation.any_instance.expects(:save).returns(true)
      Annotation.any_instance.expects(:annotatable=).with(order)
      post :create, order_id: order.id, annotation: {annotatable_type: 'Order', url: 'hams'}
      response.should redirect_to(admin_order_path(order.id))
    end
  end
end
