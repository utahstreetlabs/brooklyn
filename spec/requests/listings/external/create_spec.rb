require 'spec_helper'

describe 'Create external listing' do
  let(:source_url) { 'http://example.com/thinger' }
  let!(:source) { FactoryGirl.create(:listing_source, url: source_url) }
  let(:category) { FactoryGirl.create(:category) }
  let(:url) { "/listings/from/#{source.uuid}/create" }

  it_behaves_like 'an anonymous request' do
    before do
      xhr :post, url, format: :html
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'
    let!(:collection) { FactoryGirl.create(:collection, name: 'OMG Rad Vinyl', user: viewer)}

    context 'and the source is scraped' do
      context 'for a valid listing' do
        it 'redirects to listing path' do
          post_valid_listing_parameters
          expect(response).to redirect_to(listing_path(assigns(:listing)))
          expect(collection.listings).to include(assigns(:listing))
        end
      end

      context 'for an invalid listing' do
        it 'raises exception when the listing is invalid' do
          xhr :post, url, listing: { title: 'foo' }
          expect(response).to render_template(:new)
          expect(assigns(:listing).new_record?).to be_true
        end
      end
    end

    context 'and the source is the bookmarklet' do
      context 'for complete listing parameters' do
        it 'redirects to listing path' do
          post_valid_listing_parameters(source: 'bookmarklet')
          expect(response).to redirect_to(listing_bookmarklet_collections_path(assigns(:listing)))
          expect(collection.listings).to include(assigns(:listing))
        end
      end

      context 'for incomplete listing parameters' do
        it 'raises exception' do
          xhr :post, url, listing: { title: 'foo', source: 'bookmarklet' }
          expect(response).to render_template(:new)
          expect(assigns(:listing).new_record?).to be_true
        end
      end
    end

    def post_valid_listing_parameters(listing_options = {})
      listing_params = listing_options.reverse_merge(
        title: 'foo',
        initial_comment: 'bar',
        price: '2.00',
        category_slug: category.slug,
        description: "A description",
        source_image_id: source.images.first.id
      )
      xhr :post, url, listing: listing_params, collection_slugs: [collection.slug], format: :html
    end
  end
end
