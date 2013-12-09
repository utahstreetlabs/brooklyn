require 'spec_helper'

describe RootController do
  describe '#show' do
    context 'for a non-logged-in user' do
      it "renders the requested template" do
        get :show, template: 'bradgoreski'
        response.should render_template("root/bradgoreski")
      end

      it "returns 404 when the requested template does not exist" do
        get :show, template: 'granny-panties'
        response.status.should == 404
      end
    end

    context 'for a logged in user' do
      include_context 'for a logged-in user'

      it "renders the requested template" do
        get :show, template: 'bradgoreski'
        response.should render_template("root/bradgoreski")
      end

      it "returns 404 when the requested template does not exist" do
        get :show, template: 'granny-panties'
        response.status.should == 404
      end
    end
  end
end
