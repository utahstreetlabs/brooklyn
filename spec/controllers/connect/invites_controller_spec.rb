require 'spec_helper'

describe Connect::InvitesController do
  describe '#index' do
    it_behaves_like "secured against anonymous users" do
      before { get :index }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"

      it 'succeeds' do
        subject.current_user.person.expects(:connected_to?).with(:facebook).returns(true)
        subject.current_user.person.expects(:invite_suggestions).with(150, {:name => nil}).returns([])
        get :index
        response.should render_template(:index)
      end
    end
  end
end
