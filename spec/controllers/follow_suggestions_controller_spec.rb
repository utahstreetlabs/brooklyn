require 'spec_helper'

describe FollowSuggestionsController do
  describe "#index" do
    context "in the background" do
      it_behaves_like "xhr secured against anonymous users" do
        before { get_suggestions }
      end

      context "by a user" do
        let(:suggestion) { stub_user 'Abraham Lincoln' }
        let(:suggestions) { [suggestion] }
        let(:connections) { {suggestion.person_id => Factory.build(:social_connection)} }

        before do
          user = act_as_stub_user
          user.expects(:follow_suggestions).with(1, blacklist: ['1', '2']).returns(suggestions)
          SocialConnection.expects(:all).with(user, suggestions).returns(connections)
        end

        it "returns jsend" do
          get_suggestions
          assigns[:suggested_users].should == suggestions
          assigns[:connections].should == connections
          response.should be_jsend_success
        end
      end

      def get_suggestions
        xhr :get, :index, blacklist: ['1', '2'], format: :json
      end
    end

    context "in the foreground" do
      it_behaves_like "secured against anonymous users" do
        before { get_suggestions }
      end

      context "by a user" do
        let(:suggestion) { stub_user 'James Polk' }
        let(:suggestions) { [suggestion] }
        let(:connections) { {suggestion.person_id => Factory.build(:social_connection)} }

        before do
          user = act_as_stub_user
          user.expects(:follow_suggestions).with(1, blacklist: ['1', '2']).returns(suggestions)
          SocialConnection.expects(:all).with(user, suggestions).returns(connections)
        end

        it "returns html" do
          get_suggestions
          assigns[:suggested_users].should == suggestions
          assigns[:connections].should == connections
          response.should render_template(:index)
        end
      end

      def get_suggestions
        get :index, blacklist: [1, 2]
      end
    end
  end

  describe "#destroy" do
    let(:blacklisted) { 123 }

    it_behaves_like "xhr secured against anonymous users" do
      before { destroy_suggestion }
    end

    context "by a user" do
      before do
        user = act_as_stub_user
        user.expects(:blacklist_follow_suggestion).with(blacklisted.to_s)
      end

      it "returns jsend" do
        destroy_suggestion
        response.should be_jsend_success
      end
    end

    def destroy_suggestion
      xhr :delete, :destroy, id: blacklisted, format: :json
    end
  end
end
