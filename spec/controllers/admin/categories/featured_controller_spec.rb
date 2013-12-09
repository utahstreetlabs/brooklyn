require 'spec_helper'

describe Admin::Categories::FeaturedController do
  include_context 'category scoped'
  include_context 'listing_feature scoped'

  describe "#reorder" do
    let(:position) { '3' }

    it_behaves_like "xhr secured against anonymous users" do
      before { do_reorder }
    end

    it_behaves_like "xhr secured against rfbs" do
      before { do_reorder }
    end

    describe "as an admin user" do
      include_context 'for an admin user'
      include_context 'expects category'
      include_context 'expects listing_feature'

      it "succeeds" do
        feature.expects(:insert_at).with(position.to_i)
        category.expects(:features_with_listings).returns([])
        do_reorder
        response.should be_jsend_success
        response.jsend_data.should include('result')
      end
    end

    def do_reorder
      xhr :post, :reorder, format: :json, category_id: category.slug, id: feature.id, position: position
    end
  end

  describe "#destroy" do
    it_behaves_like "secured against anonymous users" do
      before { do_destroy }
    end

    it_behaves_like "secured against rfbs" do
      before { do_destroy }
    end

    describe "as an admin user" do
      include_context 'for an admin user'
      include_context 'expects category'
      include_context 'expects listing_feature'

      it "succeeds" do
        category.expects(:delete_feature).with(feature)
        do_destroy
        response.should redirect_to(admin_category_path(category))
        flash[:notice].should have_flash_message('admin.categories.featured.removed', listing: feature.listing.title,
          category: category.name)
      end
    end

    def do_destroy
      delete :destroy, category_id: category.slug, id: feature.id
    end
  end
end
