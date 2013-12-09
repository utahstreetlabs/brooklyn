require 'spec_helper'

describe 'Saving a listing to collections' do
  let!(:listing) { FactoryGirl.create(:active_listing) }

  it_behaves_like 'an anonymous request', xhr: true do
    before do
      save_listing(%w(one two three))
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    let!(:collections) { FactoryGirl.create_list(:collection, 3, user: viewer) }
    let!(:slugs) { collections.map(&:slug) }

    it "attaches the listing to the collections" do
      save_listing(slugs)
      collections.each do |collection|
        expect(ListingCollectionAttachment.where(listing_id: listing.id, collection_id: collection.id).first).to be
      end
    end

    it "also creates a price alert when one is desired" do
      save_listing(slugs, price_alert: '25')
      expect(PriceAlert.where(user_id: viewer.id, listing_id: listing.id).first).to be
    end

    it "does not create a price alert when one is not desired" do
      save_listing(slugs, price_alert: PriceAlert::Discounts::NONE)
      expect(PriceAlert.where(user_id: viewer.id, listing_id: listing.id).first).to be_nil
    end

    context "when posting the save when the client desires a html response" do
      it "redirects to the listing page by default" do
        save_listing(slugs, format: :html)
        expect(response).to redirect_to(listing_path(listing))
      end

      it "redirects to a provided target" do
        save_listing(slugs, format: :html, redirect: root_path)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  def save_listing(slugs, options = {})
    params = options.reverse_merge(
      collection_slugs: slugs,
      price_alert: options.fetch(:price_alert, '0'),
      format: :json
    )
    xhr(:post, "/listings/#{listing.to_param}/collections", params)
  end
end
