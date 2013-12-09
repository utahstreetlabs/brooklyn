require 'spec_helper'

describe Admin::Onboarding::InterestsController do
  let(:interests) { FactoryGirl.create_list(:interest, 3, onboarding: true) }

  describe "#index" do
    it_behaves_like "secured against anonymous users" do
      before { do_index }
    end

    it_behaves_like "secured against rfbs" do
      before { do_index }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      it "succeeds" do
        do_index
        response.should render_template(:index)
        assigns[:interests].should be
      end
    end

    def do_index
      get :index
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

      context 'when the interest is in the list' do
        it "removes the interest from the list" do
          do_destroy
          response.should redirect_to(admin_onboarding_interests_path)
          flash[:notice].should be
        end
      end

      context 'when the interest is not in the list' do
        before { interests.first.update_attributes!(onboarding: false) }

        it "does nothing" do
          do_destroy
          response.should redirect_to(admin_onboarding_interests_path)
          flash[:notice].should be
        end
      end
    end

    def do_destroy
      delete :destroy, id: interests.first.id.to_s
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

      context 'when the interest is not already in the list' do
        before { interests.first.update_attributes!(onboarding: false) }

        it "does nothing" do
          do_reorder
          response.should be_jsend_success
        end
      end

      context 'when the interest is already in the list' do
        it "moves the interest within the list" do
          do_reorder
          response.should be_jsend_success
        end
      end
    end

    def do_reorder
      xhr :post, :reorder, id: interests.first.id.to_s, format: :json
    end
  end
end
