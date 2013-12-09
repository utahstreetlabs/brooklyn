require 'spec_helper'
require 'timecop'

describe Admin::UsersController do
  let(:user) { stub_user 'Axl Rose' }

  describe "#deactivate" do
    before do
      act_as_stub_user
      can(:deactivate, user)
      User.stubs(:find).with(user.id.to_s).returns(user)
    end

    it "deactivates the user and redirects to the admin user page" do
      user.expects(:deactivate!)
      post :deactivate, id: user.id
      response.should redirect_to(admin_user_path(user.id))
      flash[:notice].should be
    end
  end

  describe "#reactivate" do
    before do
      act_as_stub_user
      can(:reactivate, user)
      User.stubs(:find).with(user.id.to_s).returns(user)
    end

    it "reactivates the user and redirects to the admin user page" do
      user.expects(:reactivate!)
      post :reactivate, id: user.id
      response.should redirect_to(admin_user_path(user.id))
      flash[:notice].should be
    end
  end
end
