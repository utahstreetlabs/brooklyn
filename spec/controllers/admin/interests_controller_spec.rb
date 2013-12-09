require 'spec_helper'

describe Admin::InterestsController do
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

  describe "#new" do
    it_behaves_like "secured against anonymous users" do
      before { do_new }
    end

    it_behaves_like "secured against rfbs" do
      before { do_new }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      it "succeeds" do
        do_new
        response.should render_template(:new)
        assigns[:interest].should be
      end
    end

    def do_new
      get :new
    end
  end

  describe "#create" do
    it_behaves_like "secured against anonymous users" do
      before { do_create }
    end

    it_behaves_like "secured against rfbs" do
      before { do_create }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      it "succeeds" do
        do_create
        response.should redirect_to(admin_interests_path)
        flash[:notice].should be
      end
    end

    def do_create
      cover_photo = fixture_file_upload('hamburgler.jpg', 'image/jpg')
      post :create, interest: {name: 'Jazzercise', onboarding: '1', cover_photo: cover_photo}
    end
  end

  describe "#destroy" do
    let(:interest) { FactoryGirl.create(:interest) }

    it_behaves_like "secured against anonymous users" do
      before { do_destroy }
    end

    it_behaves_like "secured against rfbs" do
      before { do_destroy }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      it "succeeds" do
        do_destroy
        response.should redirect_to(admin_interests_path)
        flash[:notice].should be
        expect { interest.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    def do_destroy
      delete :destroy, id: interest.id.to_s
    end
  end

  describe "#add_all_to_onboarding" do
    let(:interests) { FactoryGirl.create_list(:interest, 3, onboarding: false) }

    it_behaves_like "secured against anonymous users" do
      before { do_add_all_to_onboarding }
    end

    it_behaves_like "secured against rfbs" do
      before { do_add_all_to_onboarding }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      context "when ids are provided" do
        before { FactoryGirl.create(:global_interest) }

        it "succeeds" do
          do_add_all_to_onboarding
          response.should redirect_to(admin_interests_path)
          flash[:notice].should be
          interests.each { |i| i.reload; i.should be_onboarding }
        end
      end

      context "when ids are not provided" do
        let(:interests) { [] }

        it "fails" do
          do_add_all_to_onboarding
          response.should redirect_to(admin_interests_path)
          flash[:alert].should be
          interests.each { |i| i.reload; i.should_not be_onboarding }
        end
      end
    end

    def do_add_all_to_onboarding
      params = {}
      params[:id] = interests.map { |i| i.id.to_s } if interests.any?
      post :add_all_to_onboarding, params
    end
  end

  describe "#remove_all_from_onboarding" do
    let(:interests) { FactoryGirl.create_list(:interest, 3, onboarding: true) }

    it_behaves_like "secured against anonymous users" do
      before { do_remove_all_from_onboarding }
    end

    it_behaves_like "secured against rfbs" do
      before { do_remove_all_from_onboarding }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      context "when ids are provided" do
        it "succeeds" do
          do_remove_all_from_onboarding
          response.should redirect_to(admin_interests_path)
          flash[:notice].should be
          interests.each { |i| i.reload; i.should_not be_onboarding }
        end
      end

      context "when ids are not provided" do
        let(:interests) { [] }

        it "fails" do
          do_remove_all_from_onboarding
          response.should redirect_to(admin_interests_path)
          flash[:alert].should be
          interests.each { |i| i.reload; i.should be_onboarding }
        end
      end
    end

    def do_remove_all_from_onboarding
      params = {}
      params[:id] = interests.map { |i| i.id.to_s } if interests.any?
      post :remove_all_from_onboarding, params
    end
  end

  describe "#destroy_all" do
    let(:interests) { FactoryGirl.create_list(:interest, 3) }

    it_behaves_like "secured against anonymous users" do
      before { do_destroy_all }
    end

    it_behaves_like "secured against rfbs" do
      before { do_destroy_all }
    end

    describe "as an admin user" do
      include_context 'for an admin user'

      context "when ids are provided" do
        it "succeeds" do
          do_destroy_all
          response.should redirect_to(admin_interests_path)
          flash[:notice].should be
          interests.each { |i| expect { i.reload }.to raise_error(ActiveRecord::RecordNotFound) }
        end
      end

      context "when ids are not provided" do
        let(:interests) { [] }

        it "fails" do
          do_destroy_all
          response.should redirect_to(admin_interests_path)
          flash[:alert].should be
          interests.each { |i| expect { i.reload }.to_not raise_error }
        end
      end
    end

    def do_destroy_all
      params = {}
      params[:id] = interests.map { |i| i.id.to_s } if interests.any?
      delete :destroy_all, params
    end
  end
end
