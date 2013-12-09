require 'spec_helper'

describe Feed::ListingsController do
  let!(:user) { nil }

  describe "#index" do
    context "as an anonymous user" do
      before { get :index, format: :json }
      it_behaves_like "secured against anonymous users"
    end

    context "as a logged in user" do
      let!(:user) { act_as_stub_user(tag_likes_for: [], stubs: {last_feed_refresh_time: Time.zone.now}) }
      let(:stub_feed) { [] }

      before do
        stub_feed.stubs(:start_time).returns(0)
        stub_feed.stubs(:end_time).returns(0)
        CardFeed.expects(:new).with(user, is_a(Hash)).returns(stub_feed)
        get :index, format: :json
      end

      it "should return jsend with feed stories" do
        response.should be_jsend_success
        response.jsend_data.should include('stories')
      end
    end
  end

  describe '#destroy' do
    let(:listing_id) { 42 }
    context "as an anonymous user" do
      before { delete :destroy, id: listing_id, format: :json }
      it_behaves_like "secured against anonymous users"
    end

    context "as a logged in user" do
      let!(:user) { act_as_stub_user }
      let(:listing) { stub_listing('disliked listing', id: listing_id) }

      before do
        Listing.expects(:find).with(listing_id).returns(listing)
        Dislike.expects(:create).with(user: user, listing: listing)
        delete :destroy, id: listing_id, format: :json
      end

      it "should return success jsend" do
        response.should be_jsend_success
      end
    end
  end

  describe "#count" do
    let(:feed) { nil }

    it_behaves_like "secured against anonymous users" do
      before { get_count }
    end

    context "as a logged in user" do
      let(:time) { Time.zone.now }
      let!(:user) { act_as_stub_user(stubs: {last_feed_refresh_time: time}) }

      context 'by default' do
        it "should return jsend with count since last refresh" do
          get_count
          response.should be_jsend_success
          response.jsend_data.should include('count')
        end
      end

      context "requesting the network feed" do
        let(:feed) { 'network' }

        it "should return jsend with count since last refresh" do
          get_count
          response.should be_jsend_success
          response.jsend_data.should include('count')
        end
      end
    end

    def get_count
      get :count, format: :json, feed: feed
    end
  end
end
