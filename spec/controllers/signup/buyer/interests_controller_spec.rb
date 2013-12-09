require 'spec_helper'

describe Signup::Buyer::InterestsController do
  let!(:interest) { FactoryGirl.create(:interest, name: "pastrami", onboarding: true, gender: false) }
  let!(:interest1) { FactoryGirl.create(:interest, name: "roast beef", onboarding: false) }
  let!(:interest2) { FactoryGirl.create(:interest, name: "monte cristo", onboarding: true, gender: true) }

  describe '#index' do
    it_behaves_like "secured against anonymous users" do
      before { do_get }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user", gender: :female
      before { subject.current_user.stubs(:interests_in).returns([]) }

      it 'renders the interests page' do
        do_get
        response.should render_template(:index)
        interests = assigns(:interest_cards).interest_cards.map(&:interest)
        interests.should == [interest]
      end
    end

    def do_get
      get :index
    end
  end

  describe '#like' do
    let(:location) { '2' }

    it_behaves_like "xhr secured against anonymous users" do
      before { do_put }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"
      before { subject.current_user.stubs(:interests_remaining_count).returns(1) }

      it 'likes an interest' do
        subject.current_user.expects(:add_interest_in!).with(interest, tracking: {onboarding_location: location})
        do_put
        response.should be_jsend_success
        response.jsend_data['button'].should be
      end
    end

    def do_put
      xhr :put, :like, interest_id: interest.id, l: location, format: :json
    end
  end

  describe '#unlike' do
    it_behaves_like "xhr secured against anonymous users" do
      before { do_delete }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"
      before { subject.current_user.stubs(:interests_remaining_count).returns(1) }

      it 'unlikes an interest' do
        subject.current_user.expects(:remove_interest_in).with(interest2)
        do_delete
        response.should be_jsend_success
      end
    end

    def do_delete
      xhr :delete, :unlike, interest_id: interest2.id, format: :json
    end
  end

  describe '#complete' do
    it_behaves_like "secured against anonymous users" do
      before { do_post }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"
      before do
        subject.current_user.expects(:complete_onboarding!)
        subject.expects(:track_interests_complete)
      end

      it 'redirects to the app' do
        if feature_enabled?(:onboarding, :autofollow_collections)
          subject.current_user.expects(:follow_autofollow_collections)
        else
          subject.current_user.expects(:suggested_users).returns([])
        end
        do_post
        response.should redirect_to(root_path)
      end
    end

    def do_post
      post :complete
    end
  end
end
