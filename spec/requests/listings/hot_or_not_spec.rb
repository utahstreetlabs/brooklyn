require 'spec_helper'

describe 'Hot or not' do
  let(:listing) { FactoryGirl.create(:active_listing) }
  let(:likes_count) { 3 }

  describe 'hot' do
    it_behaves_like 'an anonymous request', xhr: true do
      before { send_hot }
    end

    context "when logged in" do
      include_context 'an authenticated session'

      it 'succeeds' do
        User.any_instance.expects(:like).with(listing)
        expect_like_counts
        send_hot
        expect(response).to be_jsend_success
        expect(response.jsend_data[:suggestions]).to be
        expect(response.jsend_data[:likes_count]).to eq(likes_count)
      end
    end

    def send_hot
      xhr :post, "/listings/#{listing.to_param}/hotness", format: :json
    end
  end

  describe 'not' do
    it_behaves_like 'an anonymous request', xhr: true do
      before { send_not }
    end

    context "when logged in" do
      include_context 'an authenticated session'

      it 'succeeds' do
        expect_like_counts
        send_not
        expect(response).to be_jsend_success
        expect(viewer.dislikes?(listing)).to be_true
        expect(response.jsend_data[:suggestions]).to be
        expect(response.jsend_data[:likes_count]).to eq(likes_count)
      end
    end

    def send_not
      xhr :delete, "/listings/#{listing.to_param}/hotness", format: :json
    end
  end

  def expect_like_counts
    # like count to determine which method we should use to fetch listings
    User.any_instance.expects(:likes_count).returns(likes_count)
    # like count to return to
    User.any_instance.expects(:likes_count).returns(likes_count + 1)
  end
end
