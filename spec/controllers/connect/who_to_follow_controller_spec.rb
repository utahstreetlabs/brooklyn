require 'spec_helper'

describe Connect::WhoToFollowController do
  describe '#index' do
    it_behaves_like "secured against anonymous users" do
      before { get :index }
    end

    context 'as a logged-in user' do
      include_context "for a logged-in user"
      before { subject.current_user.expects(:follow_suggestions) }

      it 'succeeds' do
        get :index
        response.should render_template(:index)
      end

      it 'returns jsend with user cards and links to more results' do
        count = 10
        page = 4
        controller.expects(:last_page?).returns(false)
        xhr :get, :index, format: :json, count: count, page: page

        response.should be_jsend_success
        response.jsend_data['more'].should ==
          controller.connect_who_to_follow_index_path(format: :json, count: count, page: page + 1)
      end
    end
  end
end
