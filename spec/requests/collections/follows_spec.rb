require 'spec_helper'

describe 'Collection follows' do
  let(:collection) { FactoryGirl.create(:collection, name: 'Hawt Jams') }
  describe "following" do
    it_behaves_like 'an anonymous request', xhr: true do
      before do
        follow(collection)
      end
    end

    context "when logged in" do
      include_context 'an authenticated session'

      it 'succeeds' do
        follow(collection)
        expect(response).to be_jsend_success
        expect(viewer.followed_collections).to include(collection)
      end

      it 'succeeds if the user follows twice' do
        follow(collection)
        follow(collection)
        expect(response).to be_jsend_success
      end
    end

    def follow(collection)
      xhr :put, "/collections/#{collection.id}/follow", format: :json
    end
  end

  describe "unfollowing" do
    it_behaves_like 'an anonymous request', xhr: true do
      before do
        unfollow(collection)
      end
    end

    context "when logged in" do
      include_context 'an authenticated session'
      before do
        viewer.follow_collection!(collection)
      end

      it 'succeeds' do
        unfollow(collection)
        expect(response).to be_jsend_success
        expect(viewer.followed_collections).not_to include(collection)
      end
    end

    def unfollow(collection)
      xhr :delete, "/collections/#{collection.id}/unfollow", format: :json
    end
  end
end
