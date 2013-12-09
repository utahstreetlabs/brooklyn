require 'spec_helper'

describe 'External listing collections' do
  let!(:listing) { FactoryGirl.create(:active_listing) }

  it_behaves_like 'an anonymous request', xhr: true do
    before do
      get_listing_collections(format: :json)
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    let!(:collections) { FactoryGirl.create_list(:collection, 3, user: viewer) }

    it "displays the user's collections as options" do
      get_listing_collections
      collections.each do |collection|
        expect(response.body).to include(collection.name)
      end
    end
  end

  def get_listing_collections(options = {})
    params = options.reverse_merge(
      format: :html
    )
    xhr(:get, "/listings/#{listing.to_param}/bookmarklet/collections", params)
  end
end
