require 'spec_helper'

describe 'Interests' do
  describe 'building a feed' do
    context "when not logged in" do
      it 'does not show follow button' do
        build_feed
        expect(response).to be_jsend_unauthorized
      end
    end

    context 'when logged in' do
      include_context 'an authenticated session'
      it "builds a feed" do
        StoryFeeds::CardFeed.expects(:build_feed).with(interested_user_id: viewer.id)
        build_feed
        expect(response).to be_jsend_success
      end
    end

    def build_feed
      xhr :post, "/signup/buyer/interests/feed_build", format: :json
    end
  end
end
