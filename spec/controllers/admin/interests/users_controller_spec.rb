require 'spec_helper'

describe Admin::Interests::UsersController do
  let(:interest) { FactoryGirl.create(:interest) }
  let(:user) { FactoryGirl.create(:registered_user) }

  describe "#destroy" do
    it_behaves_like "secured against anonymous users" do
      before { do_destroy }
    end

    it_behaves_like "secured against rfbs" do
      before { do_destroy }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      context 'when the user is in the list' do
        before { FactoryGirl.create(:user_suggestion, user: user, interest: interest) }

        it "removes the user from the list" do
          do_destroy
          response.should redirect_to(admin_interest_path(interest))
          flash[:notice].should be
        end
      end

      context 'when the user is not in the list' do
        it "does nothing" do
          do_destroy
          response.should redirect_to(admin_interest_path(interest))
          flash[:notice].should be
        end
      end
    end

    def do_destroy
      delete :destroy, interest_id: interest.id.to_s, id: user.id.to_s
    end
  end

  describe "#reorder" do
    it_behaves_like "xhr secured against anonymous users" do
      before { do_reorder }
    end

    it_behaves_like "xhr secured against rfbs" do
      before { do_reorder }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      context 'when the user is not already in the list' do
        it "returns an error" do
          do_reorder
          response.should be_jsend_error
        end
      end

      context 'when the user is already in the list' do
        before { FactoryGirl.create(:user_suggestion, user: user, interest: interest) }

        it "moves the user within the list" do
          do_reorder
          response.should be_jsend_success
        end
      end
    end

    def do_reorder
      xhr :post, :reorder, interest_id: interest.id.to_s, id: user.id.to_s, format: :json
    end
  end
end
