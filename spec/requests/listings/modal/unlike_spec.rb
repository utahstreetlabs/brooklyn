require 'spec_helper'

describe 'Unlike listing from modal' do
  let!(:listing) { FactoryGirl.create(:active_listing) }

  it_behaves_like 'an anonymous request', xhr: true do
    before do
      unlike_listing
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    it 'updates the ctas' do
      like = stub('like')
      User.any_instance.stubs(:unlike)
      User.any_instance.stubs(:like_for).returns(nil)
      InternalListing.any_instance.stubs(:likes_count).returns(23)
      unlike_listing
      expect(response).to be_jsend_success
      expect(response.jsend_data).to match('[data-role=ctas]')
    end
  end

  def unlike_listing
    xhr(:delete, "/listings/#{listing.to_param}/modal/like" , format: :json)
  end
end
