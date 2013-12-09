require 'spec_helper'

describe BuyersController do
  describe '#show' do
    context 'for a non-logged-in user' do
      it "renders the requested template" do
        get :show, template: 'coach-bags'
        response.should render_template("buyers/coach_bags")
      end

      it "returns 404 when the requested template does not exist" do
        get :show, template: 'granny-panties'
        response.status.should == 404
      end
    end

    context 'for a logged in user' do
      include_context 'for a logged-in user'

      it 'redirects to logged in home' do
        get :show, template: 'coach-bags'
        response.should redirect_to(root_path)
      end
    end
  end
end
