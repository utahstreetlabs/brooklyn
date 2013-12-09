require 'spec_helper'

describe NotificationsController do
  context '#index' do
    let(:user) { act_as_stub_user }

    before do
      user.expects(:mark_all_notifications_viewed)
      UserNotifications.expects(:new).returns(stub('notifications', page_manager: stub('page_manager')))
    end

    it 'renders the notifications view' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  context "#destroy" do
    let(:notification_id) { "123" }

    it_behaves_like "xhr secured against anonymous users" do
      before { click_clear_link }
    end

    context "by the notified user" do
      before do
        user = act_as_stub_user
        user.expects(:clear_notification).with(notification_id).once
      end

      before { click_clear_link }

      it "renders jsend success" do
        expect(response).to be_jsend_success
      end

      it "returns notification id" do
        expect(response.jsend_data['notificationId']).to eq(notification_id)
      end
    end

    def click_clear_link
      params = {:id => notification_id}
      xhr :delete, :destroy, {:format => :json}.merge(params)
    end
  end
end
