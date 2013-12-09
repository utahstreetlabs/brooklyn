require 'spec_helper'

describe 'Like listing from modal' do
  let!(:listing) { FactoryGirl.create(:active_listing) }

  it_behaves_like 'an anonymous request', xhr: true do
    before do
      like_listing
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    it 'updates the ctas' do
      like = stub('like')
      User.any_instance.stubs(:like).returns(like)
      User.any_instance.stubs(:like_for).returns(like)
      InternalListing.any_instance.stubs(:likes_count).returns(23)
      like_listing
      expect(response).to be_jsend_success
      expect(response.jsend_data).to match('[data-role=ctas]')
    end
  end

  def like_listing
    xhr(:put, "/listings/#{listing.to_param}/modal/like" , format: :json)
  end
end
