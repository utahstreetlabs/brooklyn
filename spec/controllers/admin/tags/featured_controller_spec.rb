require 'spec_helper'

describe Admin::Tags::FeaturedController do
  include_context 'tag scoped'
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
      include_context 'expects tag'
      include_context 'expects listing_feature'

      it "succeeds" do
        feature.expects(:insert_at).with(position.to_i)
        tag.expects(:features_with_listings).returns([])
        do_reorder
        response.should be_jsend_success
        response.jsend_data.should include('result')
      end
    end

    def do_reorder
      xhr :post, :reorder, format: :json, tag_id: tag.id, id: feature.id, position: position
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
      include_context 'expects tag'
      include_context 'expects listing_feature'

      it "succeeds" do
        tag.expects(:delete_feature).with(feature)
        do_destroy
        response.should redirect_to(admin_tag_path(tag.id))
        flash[:notice].should have_flash_message('admin.tags.featured.removed', listing: feature.listing.title,
          tag: tag.name)
      end
    end

    def do_destroy
      delete :destroy, tag_id: tag.id, id: feature.id
    end
  end
end
