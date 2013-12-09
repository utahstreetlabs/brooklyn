require 'spec_helper'

describe 'Internal listings' do
  describe 'completing a listing' do
    context 'when logged in' do
      include_context 'an authenticated session'
      let(:seller) { viewer }
      let(:listing) { FactoryGirl.create(:completable_listing, seller: seller) }
      let(:collection) { FactoryGirl.create(:collection, user: seller) }

      it 'completes the listing and redirects to the listing path' do
        complete_listing
        expect(response).to redirect_to(listing_path(listing))
        expect(listing.reload).to be_inactive
      end

      it 'adds the listing to a collection' do
        complete_listing(add_to_collection_slugs: [collection.slug])
        expect(collection.listings).to include(listing)
      end

      it 're-renders the setup form if the listing is not complete' do
        complete_listing(title: nil)
        expect(response).to be_success
      end

      def complete_listing(listing_params = {})
        params = {}
        params[:listing] = listing_params
        params[:listing][:category_id] = listing.category_id
        post("/listings/#{listing.to_param}/complete", params)
      end
    end
  end

  describe 'editing a listing' do
    context 'when logged in' do
      include_context 'an authenticated session'
      let(:listing) { FactoryGirl.create(:active_listing, seller: viewer) }
      let(:collection) { FactoryGirl.create(:collection, user: viewer) }

      it 'updates the listing and redirect to the listing path' do
        update_listing(listing, title: 'Ham Jockey')
        expect(response).to redirect_to(listing_path(listing))
        expect(listing.reload.title).to eq('Ham Jockey')
      end

      it 'adds the listing to a collection if is not yet' do
        update_listing(listing, add_to_collection_slugs: [collection.slug])
        expect(collection.reload.listings).to include(listing)
        update_listing(listing, add_to_collection_slugs: [collection.slug])
        expect(response).to redirect_to(listing_path(listing))
      end

      def update_listing(listing, listing_params = {})
        params = {}
        params[:listing] = listing_params
        params[:listing][:category_id] ||= listing.category_id
        put("/listings/#{listing.to_param}", params)
      end
    end
  end
end
