require 'spec_helper'

describe Admin::Collections::AutofollowsController do
  let(:interests) { FactoryGirl.create_list(:interest, 3) }
  let(:collection) { FactoryGirl.create(:collection) }

  describe "#set" do
    it_behaves_like "xhr secured against anonymous users" do
      before { do_set }
    end

    it_behaves_like "xhr secured against rfbs" do
      before { do_set }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      it "adds autofollows to collection for the indicated interests" do
        do_set
        response.should be_jsend_success
        response.jsend_data[:alert].should be
        response.jsend_data[:refresh].should be
        collection.autofollowed_for_interests(reload: true).should == interests
      end
    end

    def do_set
      xhr :post, :set, collection_id: collection.id.to_s, collection: {autofollowed_interest_ids: interests.map { |i| i.id.to_s} },
        format: :json
    end
  end
end
