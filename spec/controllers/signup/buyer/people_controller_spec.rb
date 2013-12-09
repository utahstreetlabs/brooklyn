require 'spec_helper'

describe Signup::Buyer::PeopleController do
  describe '#index' do
    it_behaves_like "secured against anonymous users" do
      before { do_get }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"

      it 'renders the users page' do
        users = []
        User.expects(:autofollow_list).returns(users)
        cards = []
        followees = []
        subject.current_user.expects(:interest_based_followees).returns(followees)
        subject.current_user.expects(:followees).returns(followees)
        do_get
        assigns(:followees).should == followees
        response.should render_template(:index)
      end
    end

    def do_get
      get :index
    end
  end

  describe '#complete' do
    it_behaves_like "secured against anonymous users" do
      before { do_post }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"

      it 'renders the users page' do
        subject.current_user.expects(:complete_onboarding!)
        do_post
        response.should redirect_to(root_path)
      end
    end

    def do_post
      post :complete
    end
  end
end
