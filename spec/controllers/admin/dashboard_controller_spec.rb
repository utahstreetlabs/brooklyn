require 'spec_helper'

describe Admin::DashboardController do
  context "#show" do
    before do
      act_as_stub_user(admin: true)
      AdminStats.expects(:new).returns(stub_everything)
    end

    it "assigns stats" do
      get :show
      assigns(:stats).should be
    end
  end
end
