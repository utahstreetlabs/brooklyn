require 'spec_helper'
require 'action_view'

include ActionView::Helpers::DateHelper

describe 'View listing modal' do
  let!(:seller) { FactoryGirl.create(:registered_user) }
  let!(:listing) { FactoryGirl.create(:active_listing, seller: seller) }
  before do
    InternalListing.any_instance.stubs(:likes_count).returns(23)
    InternalListing.any_instance.stubs(:comment_summary).returns(stub('comment-summary', comments: {}))
    User.any_instance.stubs(:like_for).returns(nil)
  end

  context 'when anonymous' do
    it 'returns the modal' do
      get_listing_modal
      expect(response).to be_jsend_success
      expect(response.jsend_data[:modal]).to be
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    context "for an internal listing" do
      it 'returns the modal' do
        get_listing_modal
        expect(response).to be_jsend_success
        expect(response.jsend_data[:modal]).to be
        expect(response.jsend_data[:saveManager]).to be
      end

      context "in the header" do
        let(:collection) { FactoryGirl.create(:collection, user: seller) }

        context "when the listing is part of the seller's collections" do
          before do
            collection.add_listing(listing)
          end

          it "successfully renders the story" do
            get_listing_modal
            expect(response.jsend_data[:modal]).to match(/#{public_profile_collection_path(listing.seller, collection)}/)
          end
        end

        context "when the listing is not part of the seller's collections" do
          it "successfully renders the story" do
            get_listing_modal
            expect(response.jsend_data[:modal]).to_not match(/#{public_profile_collection_path(listing.seller, collection)}/)
          end
        end
      end

      context "in the footer" do
        let(:collection) { FactoryGirl.create(:collection, user: seller) }

        context "when the listing is part of the seller's collections" do
          let(:collection_listing) { FactoryGirl.create(:active_listing, seller: seller) }

          before do
            collection.add_listing(listing)
            collection.add_listing(collection_listing)
          end

          it "successfully renders the carousel" do
            get_listing_modal
            expect(response.jsend_data[:modal]).to match(/thumbnail-#{listing.photos.first.id}.*thumbnail-#{collection_listing.photos.first.id}/)
          end

          it "updates the modal top content" do
            get_listing_modal_top(collection: collection)
            expect(response).to be_jsend_success
            expect(response.jsend_data[:modalTop]).to match(/#{public_profile_collection_path(listing.seller, collection)}/)
            expect(response.jsend_data[:modalTop]).to_not match(/thumbnail/)
          end
        end

        context "when the listing is not part of the seller's collections" do
          let!(:loved_listing) { FactoryGirl.create(:active_listing) }

          before do
            Listing.stubs(:liked_by).returns([loved_listing])
          end

          it "successfully renders the carousel" do
            get_listing_modal
            expect(response.jsend_data[:modal]).to match(/thumbnail-#{listing.photos.first.id}/)
            expect(response.jsend_data[:modal]).to match(/thumbnail-#{loved_listing.photos.first.id}/)
          end

          it "updates the modal top content" do
            get_listing_modal_top
            expect(response).to be_jsend_success
            expect(response.jsend_data[:modalTop]).to_not match(/#{public_profile_collection_path(listing.seller, collection)}/)
            expect(response.jsend_data[:modalTop]).to_not match(/thumbnail/)
          end
        end
      end
    end

    context "for an external listing" do
      let!(:listing) { FactoryGirl.create(:external_listing, seller: seller) }

      before do
        ExternalListing.any_instance.stubs(:likes_count).returns(23)
        ExternalListing.any_instance.stubs(:comment_summary).returns(stub('comment-summary', comments: {}))
      end

      it 'returns the modal' do
        get_listing_modal
        expect(response).to be_jsend_success
        expect(response.jsend_data[:modal]).to be
        expect(response.jsend_data[:saveManager]).to be
      end

      context "in the header" do
        let(:collection) { FactoryGirl.create(:collection, user: seller) }

        context "when the listing is part of the seller's collections" do
          before do
            ListingCollectionAttachment.create!(collection_id: collection.id, listing_id: listing.id)
          end

          it "successfully renders the story" do
            get_listing_modal
            expect(response.jsend_data[:modal]).to match(/#{public_profile_collection_path(listing.seller, collection)}/)
          end
        end

        context "when the listing is not part of the seller's collections" do
          it "successfully renders the story" do
            get_listing_modal
            expect(response.jsend_data[:modal]).to_not match(/#{public_profile_collection_path(listing.seller, collection)}/)
          end
        end
      end
    end
  end

  def get_listing_modal
    xhr :get, "/listings/#{listing.to_param}/modal", format: :json
  end

  def get_listing_modal_top(options = {})
    url = "/listings/#{listing.to_param}/modal/top"
    url << "?collection=#{collection.id}" if options[:collection]
    xhr :get, url, format: :json
  end
end
