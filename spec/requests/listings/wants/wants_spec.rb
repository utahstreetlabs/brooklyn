require 'spec_helper'

describe 'Want a listed item' do
  let(:user) { FactoryGirl.create(:registered_user) }
  let!(:listing) { FactoryGirl.create(:active_listing, seller: user) }
  let!(:collection) { FactoryGirl.create(:collection, user: user) }

  before do
    collection.add_listing(listing)
  end

  context 'when it is not already wanted' do
    it_behaves_like 'an anonymous request', xhr: true do
      before { want_listed_item }
    end

    context "when logged in" do
      include_context 'an authenticated session'

      context "as an rfb" do
        it 'errors' do
          want_listed_item
          expect(response).to be_jsend_error
        end
      end

      context "as the collection owner" do
        let(:user) { viewer }

        context "with valid params" do
          it 'succeeds' do
            want_listed_item
            expect(response).to be_jsend_success
            expect(response.jsend_data[:followupModal]).to be
            expect(user.want_for_item(listing.item)).to be
          end
        end

        context "with invalid params" do
          it 'succeeds' do
            want_listed_item(max_price: -5)
            expect(response).to be_jsend_failure
            expect(response.jsend_data[:modal]).to be
            expect(user.want_for_item(listing.item)).to be_nil
          end
        end
      end
    end

    def want_listed_item(params = {})
      params.reverse_merge!(max_price: 5)
      xhr :post, "/listings/#{listing.to_param}/collections/#{collection.to_param}/wants", format: :json, want: params
    end
  end

  context 'when it is already wanted' do
    let!(:want) { FactoryGirl.create(:want, user: user, item: listing.item) }

    it_behaves_like 'an anonymous request', xhr: true do
      before { want_listed_item }
    end

    context "when logged in" do
      include_context 'an authenticated session'

      context "as an rfb" do
        it 'errors' do
          want_listed_item
          expect(response).to be_jsend_error
        end
      end

      context "as the collection owner" do
        let(:user) { viewer }

        context "with valid params" do
          it 'succeeds' do
            want_listed_item
            expect(response).to be_jsend_success
            expect(response.jsend_data[:followupModal]).to be
            expect(user.want_for_item(listing.item)).to be
          end
        end

        context "with invalid params" do
          it 'succeeds' do
            want_listed_item(max_price: -5)
            expect(response).to be_jsend_failure
            expect(response.jsend_data[:modal]).to be
            expect(user.want_for_item(listing.item).max_price).to_not eq(-5)
          end
        end
      end
    end

    def want_listed_item(params = {})
      xhr :put, "/listings/#{listing.to_param}/collections/#{collection.to_param}/wants/#{want.id}", format: :json,
          want: params
    end
  end
end