require 'spec_helper'

describe 'Listings' do
  let(:collections) { FactoryGirl.create_list(:collection, 3) }
  let!(:listing) { FactoryGirl.create(:active_listing) }
  let(:comment_text) { 'Holler back yall' }
  before { InternalListing.any_instance.stubs(:comment) }

  describe "add to collections" do
    it_behaves_like 'an anonymous request', xhr: true do
      before do
        add_to_collections(listing, collections, comment_text)
      end
    end

    context "when logged in" do
      include_context 'an authenticated session'
      let(:collections) { FactoryGirl.create_list(:collection, 3, user: viewer) }

      it 'succeeds for a generic collection' do
        InternalListing.any_instance.expects(:comment).with(viewer, {text: comment_text}, source: :save_modal)
        add_to_collections(listing, collections, comment_text)
        expect_standard_response
        expect(viewer.collection_listings).to include(listing)
        expect(viewer).to_not have_item(listing.item)
      end

      it 'succeeds for a have collection' do
        InternalListing.any_instance.expects(:comment).with(viewer, {text: comment_text}, source: :save_modal)
        add_to_collections(listing, collections, comment_text, have: true)
        expect_standard_response
        expect(viewer.collection_listings).to include(listing)
        expect(viewer).to have_item(listing.item)
      end

      it 'succeeds for a want collection' do
        InternalListing.any_instance.expects(:comment).with(viewer, {text: comment_text}, source: :save_modal)
        User.any_instance.expects(:want_for_item).with(listing.item).returns(nil) # proves want path followed
        add_to_collections(listing, collections, comment_text, want: true)
        expect_standard_response
        expect(viewer.collection_listings).to include(listing)
        expect(viewer).to_not have_item(listing.item)
      end

      it 'succeeds even if the comment is blank' do
        InternalListing.any_instance.expects(:comment).never
        add_to_collections(listing, collections, '')
        expect_standard_response
      end

      # this is fine because it'll only happen if the user deletes a collection
      it 'silently fails to add a listing to a collection for a nonexistent collection' do
        add_to_collections(listing, collections << 'foo-bar', comment_text)
        expect_standard_response
      end

      it "fails if the listing doesn't exist" do
        add_to_collections('hams', collections, comment_text)
        expect(response).to be_jsend_error
      end

      it "doesn't add to collections not owned by this user" do
        other_collection = FactoryGirl.create(:collection)
        add_to_collections(listing, collections << other_collection, comment_text)
        expect_standard_response
        expect(other_collection.reload.listings).to be_empty
      end
    end

    def add_to_collections(listing, colls, comment_text, options = {})
      update_collections(listing, colls, comment_text, options.merge(method: :post))
    end
  end


  describe "update collections" do
    it_behaves_like 'an anonymous request', xhr: true do
      before do
        update_collections(listing, collections, comment_text)
      end
    end

    context "when logged in" do
      include_context 'an authenticated session'
      let(:collections) { FactoryGirl.create_list(:collection, 3, user: viewer) }

      it 'updates the collections to which the listing is saved' do
        update_collections(listing, collections, '')
        expect_standard_response
        expect(listing.collections_owned_by(viewer)).to eq(collections)
        update_collections(listing, [], '')
        expect_standard_response(false)
        expect(listing.collections_owned_by(viewer)).to eq([])
      end

      it 'succeeds for a generic collection' do
        InternalListing.any_instance.expects(:comment).with(viewer, {text: comment_text}, source: :save_modal)
        update_collections(listing, collections, comment_text)
        expect_standard_response
        expect(listing.collections_owned_by(viewer)).to eq(collections)
        expect(viewer).to_not have_item(listing.item)
      end

      it 'succeeds for a have collection' do
        InternalListing.any_instance.expects(:comment).with(viewer, {text: comment_text}, source: :save_modal)
        update_collections(listing, collections, comment_text, have: true)
        expect_standard_response
        expect(listing.collections_owned_by(viewer)).to eq(collections)
        expect(viewer).to have_item(listing.item)
      end

      it 'succeeds for a want collection' do
        InternalListing.any_instance.expects(:comment).with(viewer, {text: comment_text}, source: :save_modal)
        User.any_instance.expects(:want_for_item).with(listing.item).returns(nil) # proves want path followed
        update_collections(listing, collections, comment_text, want: true)
        expect_standard_response
        expect(listing.collections_owned_by(viewer)).to eq(collections)
        expect(viewer).to_not have_item(listing.item)
      end

      it 'succeeds even if the comment is blank' do
        InternalListing.any_instance.expects(:comment).never
        update_collections(listing, collections, '')
        expect_standard_response
        expect(listing.collections_owned_by(viewer)).to eq(collections)
      end

      # this is fine because it'll only happen if the user deletes a collection
      it 'silently fails to add a listing to a collection for a nonexistent collection' do
        update_collections(listing, collections + ['foo-bar'], comment_text)
        expect_standard_response
        expect(listing.collections_owned_by(viewer)).to eq(collections)
      end

      it "fails if the listing doesn't exist" do
        update_collections('hams', collections, comment_text)
        expect(response).to be_jsend_error
        expect(listing.collections_owned_by(viewer)).to eq([])
      end

      it "doesn't add to collections not owned by this user" do
        other_collection = FactoryGirl.create(:collection)
        update_collections(listing, collections + [other_collection], comment_text)
        expect_standard_response
        expect(listing.collections_owned_by(viewer)).to eq(collections)
      end
    end
  end

  def expect_standard_response(stats = true)
    expect(response).to be_jsend_success
    expect(response.jsend_data[:followupModal]).to be
    expect(response.jsend_data[:saveButton]).to be
    expect(response.jsend_data[:stats]).to be if stats
    expect(response.jsend_data[:listingId]).to eq(listing.id)
  end

  def update_collections(listing, colls, comment_text, options = {})
    params = {
      format: :json,
      collection_slugs: to_params(colls),
      comment: comment_text
    }
    params[:have] = "1" if options[:have]
    params[:want] = "1" if options[:want]
    method = options[:method] || :put
    xhr method, "/listings/#{to_params(listing)}/collections", params
  end

  def to_params(records)
    params = Array.wrap(records).map do |r|
      r.respond_to?(:to_param) ? r.to_param : r
    end
    records.is_a?(Array) ? params : params.first
  end
end
