require 'spec_helper'

describe 'Build external listing' do
  let(:source_url) { 'http://example.com/thinger' }
  let!(:source) { FactoryGirl.create(:listing_source, url: source_url) }
  let(:url) { "/listings/from/#{source.uuid}/new" }

  it_behaves_like 'an anonymous request' do
    before do
      xhr :post, url, format: :html
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    context 'and the source is the bookmarklet' do
      context "when a listing for the source url exists" do
        let!(:listing) { FactoryGirl.create(:external_listing, source: source) }

        it "adds a new user like for the listing" do
          Pyramid::User::Likes.expects(:create).returns
          post_request
          expect(response).to redirect_to(listing_bookmarklet_collections_path(listing))
        end
      end

      context "when a listing for the source url does not exist" do
        it 'renders the page' do
          post_request
          expect(response).to render_template(:new)
          expect(assigns(:listing).new_record?).to be_true
        end
      end
    end

    def post_request(options = {})
      params = options.reverse_merge(
        source: 'bookmarklet'
      )
      xhr :post, url, params
    end
  end
end
