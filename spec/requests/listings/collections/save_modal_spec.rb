require 'spec_helper'

describe 'View save listing modal' do
  let!(:listing) { FactoryGirl.create(:active_listing) }

  it_behaves_like 'an anonymous request', xhr: true do
    before do
      get_save_modal
    end
  end

  context "when logged in" do
    let!(:collections) { FactoryGirl.create_list(:collection, 3, user: viewer) }
    include_context 'an authenticated session'

    it "lists each collection" do
      get_save_modal
      collections.each do |collection|
        expect(response.jsend_data[:modal]).to match(/#{collection.name}/)
      end
    end
  end

  def get_save_modal
    xhr :get, "/listings/#{listing.to_param}/collections/save_modal", format: :json
  end
end
