require 'spec_helper'

describe HomeController do
  describe '#index' do
    context "invoked by an anonymous user" do
      it "should show the logged-out home page" do
        get :index
        response.should render_template(:index)
      end
    end

    context "invoked by a connected user" do
      before { act_as_stub_user(connected: true) }

      it 'should redirect to the buyer signup flow by default' do
        get :index
        response.should redirect_to new_signup_buyer_profile_path
      end

      it 'should redirect to the buyer signup flow' do
        get :index, s: 'b'
        response.should redirect_to new_signup_buyer_profile_path
      end

      it 'should redirect to the seller signup flow' do
        get :index, s: 's'
        response.should redirect_to new_profile_path
      end
    end

    context "invoked by a logged-in user" do
      before { act_as_stub_user }

      feature_flag('feed.follow_card.fb')
      feature_flag('feed.invite_card.fb_feed_dialog')
      feature_flag('home.logged_in.collection_carousel')
      feature_flag('home.logged_in.popular_experiment', enabled: false)
      feature_flag('home.logged_in.trending_experiment', enabled: false)
      it "should show the logged-in home page" do
        subject.stubs(:load_listings_feed)
        subject.stubs(:load_top_messages)
        subject.stubs(:load_tutorial_bar)
        subject.stubs(:load_collection_carousel)
        subject.stubs(:load_and_forget_invite_bar_request)
        get :index
        response.should render_template(:logged_in)
      end
    end
  end
end
