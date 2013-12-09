require 'spec_helper'

describe Admin::Users::SuggestionsController do
  let(:interests) { FactoryGirl.create_list(:interest, 3) }
  let(:user) { FactoryGirl.create(:registered_user) }

  describe "#set" do
    it_behaves_like "xhr secured against anonymous users" do
      before { do_set }
    end

    it_behaves_like "xhr secured against rfbs" do
      before { do_set }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      it "adds suggests the user for the indicated interests" do
        do_set
        response.should be_jsend_success
        response.jsend_data[:alert].should be
        response.jsend_data[:refresh].should be
        user.suggested_for_interests(reload: true).should == interests
      end
    end

    def do_set
      xhr :post, :set, user_id: user.id.to_s, user: {suggested_interest_ids: interests.map { |i| i.id.to_s} },
        format: :json
    end
  end
end
