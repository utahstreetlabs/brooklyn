require 'spec_helper'

describe 'Feature a listed item' do
  let(:user) { FactoryGirl.create(:registered_user) }
  let!(:listing) { FactoryGirl.create(:active_listing, seller: user) }
  let(:modal_url) { "/listings/#{listing.slug}/features/feature_modal" }

  context "when viewing the feature modal" do
    it_behaves_like 'an anonymous request', xhr: true do
      before do
        get_feature_modal
      end
    end

    context "when logged in" do
      context "as a regular user" do
        include_context 'a non-admin request', xhr: true

        before do
          get_feature_modal
        end
      end

      context "as an admin" do
        let(:tag) { FactoryGirl.create(:tag, name: 'sad panda') }
        let(:category) { FactoryGirl.create(:category, name: 'Accessories') }
        let!(:feature_list) { FactoryGirl.create(:feature_list, name: 'Best of the Best') }

        include_context 'an authenticated session', admin: true

        it 'returns the modal' do
          get_feature_modal
          expect(response).to be_jsend_success
          expect(response.jsend_data[:modal]).to be
        end

        it 'contains the tag' do
          listing.tags << tag
          listing.save!
          get_feature_modal
          expect(response.jsend_data[:modal]).to match(/#{tag.name}/)
        end

        it 'contains the category' do
          listing.category = category
          listing.save!
          get_feature_modal
          expect(response.jsend_data[:modal]).to match(/#{category.name}/)
        end

        it 'contains the feature list' do
          get_feature_modal
          expect(response.jsend_data[:modal]).to match(/#{feature_list.name}/)
        end

        context "when listing is featured" do
          it 'contains the selected tag' do
            listing.tags << tag
            listing.features.create!(featurable: tag)
            listing.save!
            listing.reload
            get_feature_modal
            expect(response.jsend_data[:modal]).to match(/#{tag.name}/)
            expect(response.jsend_data[:modal]).to match(/checked=\"checked\".*#{tag.name}/)
          end

          it 'contains the selected category' do
            listing.category = category
            listing.features.create!(featurable: category)
            listing.save!
            listing.reload
            get_feature_modal
            expect(response.jsend_data[:modal]).to match(/#{category.name}/)
            expect(response.jsend_data[:modal]).to match(/checked=\"checked\".*#{category.name}/)
          end

          it 'contains the selected feature list' do
            listing.features.create!(featurable: feature_list)
            listing.save!
            listing.reload
            get_feature_modal
            expect(response.jsend_data[:modal]).to match(/#{feature_list.name}/)
            expect(response.jsend_data[:modal]).to match(/checked=\"checked\".*#{feature_list.name}/)
          end
        end
      end
    end

    def get_feature_modal
      xhr :get, modal_url, format: :json
    end
  end

  context "when updating a listing's features" do
    let(:tag) { FactoryGirl.create(:tag, name: 'sad panda') }
    let(:category) { FactoryGirl.create(:category, name: 'Accessories') }
    let(:feature_list) { FactoryGirl.create(:feature_list, name: 'Best of the Best') }

    it_behaves_like 'an anonymous request', xhr: true do
      before do
        update_listing_features(category_id: category.id)
      end
    end

    context "when logged in" do
      context "as a regular user" do
        include_context 'a non-admin request', xhr: true

        before do
          update_listing_features(category_id: category.id)
        end
      end

      context "as an admin" do
        include_context 'an authenticated session', admin: true

        it "adds a new category feature" do
          update_listing_features(category_id: category.id)
          expect(response).to be_jsend_success
          expect(response.jsend_data[:followupModal]).to be
          expect(response.jsend_data[:replace]).to be
          listing.reload
          expect(listing.category_feature).to be
        end

        it "adds a new tag feature" do
          update_listing_features(:"tag_ids[]" => tag.id)
          expect(response).to be_jsend_success
          expect(response.jsend_data[:followupModal]).to be
          expect(response.jsend_data[:replace]).to be
          listing.reload
          expect(listing.tag_features.count == 1)
        end

        it "adds a new feature list feature" do
          update_listing_features(:"feature_list_ids[]" => feature_list.id)
          expect(response).to be_jsend_success
          expect(response.jsend_data[:followupModal]).to be
          expect(response.jsend_data[:replace]).to be
          listing.reload
          expect(listing.feature_list_features.count == 1)
        end

        it "removes a category feature" do
          listing.category = category
          listing.features.create!(featurable: category)
          listing.save!
          listing.reload
          update_listing_features
          expect(response).to be_jsend_success
          expect(response.jsend_data[:followupModal]).to be
          expect(response.jsend_data[:replace]).to be
          listing.reload
          expect(listing.category_feature).to be_nil
        end

        it "removes a tag feature" do
          listing.tags << tag
          listing.features.create!(featurable: tag)
          listing.save!
          listing.reload
          update_listing_features
          expect(response).to be_jsend_success
          expect(response.jsend_data[:followupModal]).to be
          expect(response.jsend_data[:replace]).to be
          listing.reload
          expect(listing.tag_features.count == 0)
        end

        it "removes a feature list feature" do
          listing.features.create!(featurable: feature_list)
          listing.save!
          listing.reload
          update_listing_features
          expect(response).to be_jsend_success
          expect(response.jsend_data[:followupModal]).to be
          expect(response.jsend_data[:replace]).to be
          listing.reload
          expect(listing.feature_list_features.count == 0)
        end
      end
    end

    def update_listing_features(params = {})
      xhr :put, "/listings/#{listing.slug}/features", params.merge(format: :json)
    end
  end
end
