require 'spec_helper'

describe Settings::ProfileController do
  describe "#show" do
    it_behaves_like "secured against anonymous users" do
      before { get :show }
    end

    context "for a logged-in user" do
      before { act_as_stub_user }

      it "shows the page" do
        get :show
        response.should render_template(:show)
      end
    end
  end
end
