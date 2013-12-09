require 'spec_helper'

describe 'Collections' do
  describe "create collection" do
    it_behaves_like 'an anonymous request', xhr: true do
      before do
        create_collection(name: 'Pork')
      end
    end

    context "when logged in" do
      include_context 'an authenticated session'

      it 'succeeds' do
        create_collection(name: 'Pork')
        expect(response).to be_jsend_success
        expect(response.jsend_data[:modal]).to be
        expect(response.jsend_data[:followupModal]).to be
        expect(viewer.collections.map(&:name)).to include('Pork')
      end

      it 'succeeds if this user already created a collection with this name' do
        create_collection(name: 'Pork')
        create_collection(name: 'Pork')
        expect(response).to be_jsend_success
        expect(response.jsend_data[:modal]).to be
        expect(response.jsend_data[:followupModal]).to be
      end

      it 'fails when the name is invalid' do
        create_collection(name: '=!@##$%#^$#^$%&^%^*%^&*&()')
        expect(response).to be_jsend_failure
        expect(response.jsend_data[:modal]).to be
        expect(response.jsend_data[:errors]).to be
      end

      it "populates attributes when creating a new collection" do
        create_collection(name: 'Pork')
        expect(response).to be_jsend_success
        expect(response.jsend_data[:name]).to be
        expect(response.jsend_data[:modal]).to be
        expect(response.jsend_data[:followupModal]).to be
      end

      it "renders a new list item when called from a dropdown context" do
        create_collection(name: 'Pork', context: :standalone)
        expect(response).to be_jsend_success
        expect(response.jsend_data[:list_item]).to be
        expect(response.jsend_data[:modal]).to_not be
        expect(response.jsend_data[:followupModal]).to_not be
      end
    end

    def create_collection(options = {})
      params = {format: :json, collection: {}}
      params[:collection][:name] = options[:name] if options[:name]
      params[:collection][:context] = options[:context] if options[:context]
      xhr :post, "/collections", params
    end
  end

  describe 'populate collection' do
    let(:listings) { FactoryGirl.create_list(:active_listing, 2) }

    it_behaves_like 'an anonymous request', xhr: true do
      let(:collection) { FactoryGirl.create(:collection) }
      before { populate_collection }
    end

    context "when logged in" do
      include_context 'an authenticated session'

      context "and populating own collection" do
        let!(:collection) { FactoryGirl.create(:collection, user: viewer) }

        it 'succeeds' do
          populate_collection
          expect(response).to be_jsend_success
          expect(response.jsend_data[:followupModal]).to be
          expect(collection.listings.reload).to have(2).listings
        end
      end

      context "and populating another's collection" do
        let!(:collection) { FactoryGirl.create(:collection) }

        it 'fails' do
          populate_collection
          expect(response).to be_jsend_failure
          expect(collection.listings.reload).to be_empty
        end
      end
    end

    def populate_collection
      xhr :post, "/collections/#{collection.id}/populate", format: :json, listing_id: listings.map(&:id)
    end
  end

  describe "show collections" do
    context "when not logged in" do
      let!(:collection) { FactoryGirl.create(:collection) }

      it 'does not show follow button' do
        show_collections(collection.owner)
        expect(response.body).to_not match(/#{collection_follow_path(collection.id)}/)
      end
    end

    context "when logged in" do
      include_context 'an authenticated session'

      context 'when viewer is owner' do
        let!(:collection) { FactoryGirl.create(:collection, user: viewer) }

        it 'shows edit button' do
          show_collections(viewer)
          expect(response.body).to match(/#{collection_path(collection.id)}/)
        end
      end

      context 'when viewer is not owner' do
        let(:collection) { FactoryGirl.create(:collection) }

        it 'shows follow button' do
          show_collections(collection.owner)
          expect(response.body).to match(/#{collection_follow_path(collection.id)}/)
        end
      end
    end

    def show_collections(user)
      xhr :get, "/profiles/#{user.slug}/collections"
    end
  end

  describe "add listing" do
    let(:collection) { FactoryGirl.create(:collection) }
    let!(:listing) { FactoryGirl.create(:active_listing) }
    it_behaves_like 'an anonymous request', xhr: true do
      before do
        add_listing(collection, listing)
      end
    end

    context "when logged in" do
      include_context 'an authenticated session'
      let(:collection) { FactoryGirl.create(:collection, user: viewer) }

      it 'succeeds' do
        add_listing(collection, listing)
        expect(response).to be_jsend_success
        expect(viewer.collection_listings).to include(listing)
      end

      it 'fails if the collection does not exist' do
        add_listing('ham-products', listing)
        expect(response).to be_jsend_failure
      end
    end

    def add_listing(collection, listing)
      xhr :post, "/collections/#{collection.to_param}/listings", format: :json, id: listing.to_param
    end
  end

  describe "remove listing" do
    let(:collection) { FactoryGirl.create(:collection) }
    let!(:listing) { FactoryGirl.create(:active_listing) }
    before { collection.add_listing(listing) }
    it_behaves_like 'an anonymous request', xhr: true do
      before do
        remove_listing(collection, listing)
      end
    end

    context "when logged in" do
      include_context 'an authenticated session'
      let(:collection) { FactoryGirl.create(:collection, user: viewer) }

      it 'succeeds' do
        remove_listing(collection, listing)
        expect(response).to be_jsend_success
        expect(response.jsend_data[:refresh]).to be
        expect(viewer.collection_listings).not_to include(listing)
      end

      it 'is idempotent' do
        remove_listing(collection, listing)
        expect(response).to be_jsend_success
        remove_listing(collection, listing)
        expect(response).to be_jsend_success
      end

      it 'fails if the collection does not exist' do
        remove_listing('ham-products', listing)
        expect(response).to be_jsend_failure
      end

      it 'fails if the listing does not exist' do
        remove_listing(collection, 'ham-hat')
        expect(response).to be_jsend_failure
      end
    end

    def remove_listing(collection, listing)
      xhr :delete, "/collections/#{collection.to_param}/listings/#{listing.to_param}", format: :json
    end
  end

  describe "update collection" do
    let(:collection) { FactoryGirl.create(:collection) }

    it_behaves_like 'an anonymous request', xhr: true do
      before do
        update_collection(collection.id, name: "Shakes to handle & beast")
      end
    end

    context "when logged in" do
      include_context 'an authenticated session'
      let(:collection) { FactoryGirl.create(:collection, user: viewer) }

      it "succeeds" do
        update_collection(collection.id, "Burgers that have strength")
        expect(response).to be_jsend_success
      end

      context "when the collection is not editable" do
        let(:collection) { FactoryGirl.create(:collection, user: viewer, editable: false) }

        it "fails" do
          update_collection(collection.id, "Burgers that have strength")
          expect(response).to be_jsend_failure
        end
      end

      context "when the collection belongs to another user" do
        let(:other_user) { FactoryGirl.create(:registered_user) }
        let(:collection) { FactoryGirl.create(:collection, user: other_user) }

        it 'fails' do
          update_collection(collection.id, "Burgers that have strength")
          expect(response).to be_jsend_failure
        end
      end
    end

    def update_collection(id, name)
      xhr :put, "/collections/#{id}", format: :json, collection: { name: name }
    end
  end

  describe "delete collection" do
    let(:collection) { FactoryGirl.create(:collection) }

    it_behaves_like 'an anonymous request', xhr: true do
      before do
        delete_collection(collection.id)
      end
    end

    context "when logged in" do
      include_context 'an authenticated session'
      let(:collection) { FactoryGirl.create(:collection, user: viewer) }

      it "succeeds" do
        delete_collection(collection.id)
        expect(response).to be_jsend_success
      end

      context "when the collection is not editable" do
        let(:collection) { FactoryGirl.create(:collection, user: viewer, editable: false) }

        it "fails" do
          delete_collection(collection.id)
          expect(response).to be_jsend_failure
        end
      end

      context "when the collection belongs to another user" do
        let(:other_user) { FactoryGirl.create(:registered_user) }
        let(:collection) { FactoryGirl.create(:collection, user: other_user) }

        it "fails" do
          delete_collection(collection.id)
          expect(response).to be_jsend_failure
        end
      end
    end

    def delete_collection(id)
      xhr :delete, "/collections/#{id}", format: :json
    end
  end
end
