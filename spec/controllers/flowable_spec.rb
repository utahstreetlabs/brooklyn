require 'spec_helper'

class FlowableController < ActionController::Base
  include Controllers::Flowable
end

describe FlowableController do
  controller(FlowableController) do
    def create
      store_register_redirect(params[:redirect])
      render inline: ''
    end

    def index
      redirect_after_register
    end
  end

  let(:redirect_url) { "http://example.com/some/awesome/url" }
  let(:redirect_url2) { "http://example.com/another/awesomer/url" }
  describe "#index" do
    it "should redirect to a url" do
      post :create, redirect: redirect_url
      get :index
      response.should redirect_to(redirect_url)
    end

    it "should be able to redirect multiple times" do
      post :create, redirect: [redirect_url, redirect_url2]
      get :index
      response.should redirect_to(redirect_url)
      get :index
      response.should redirect_to(redirect_url2)
    end

    it "should be able to redirect to registered urls based on a key" do
      subject.class_eval "register_redirects :hams, ['#{redirect_url}', '#{redirect_url2}']"
      post :create, redirect: :hams
      get :index
      response.should redirect_to(redirect_url)
      get :index
      response.should redirect_to(redirect_url2)
    end

    it "should be able to redirect to registered urls based on a key using block syntax" do
      subject.class_eval "register_redirects(:hams) { ['#{redirect_url}', '#{redirect_url2}'] }"
      post :create, redirect: :hams
      get :index
      response.should redirect_to(redirect_url)
      get :index
      response.should redirect_to(redirect_url2)
    end

    it "evaluate registered redirect blocks in the context of the request that sets the redirects" do
      subject.class_eval "register_redirects(:hams) { [params[:beans]] }"
      post :create, redirect: :hams, beans: 'pickles'
      get :index
      response.should redirect_to('pickles')
    end

    it "evaluates registered redirects recursively" do
      subject.class_eval "register_redirects(:hams) { [:bacon] }"
      subject.class_eval "register_redirects(:bacon) { ['http://example.com/pickles'] }"
      post :create, redirect: :hams
      get :index
      response.should redirect_to('http://example.com/pickles')
    end

    it "should not redirect to a url visited by an xhr" do
      xhr :post, :create, redirect: redirect_url
      get :index
      response.should_not redirect_to(redirect_url)
    end
  end
end
