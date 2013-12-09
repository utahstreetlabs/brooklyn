require 'spec_helper'

describe Admin::Users::AutofollowsController do
  let(:user) { stub_user 'Don Draper' }
  before do
    act_as_stub_user
    can(:manage, UserAutofollow)
    User.stubs(:find).with(user.id.to_s).returns(user)
  end

  describe '#index' do
    it 'finds the autofollow list of users renders the index template' do
      autofollow_list = mock
      User.expects(:autofollow_list).returns(autofollow_list)
      get :index
      response.should render_template(:index)
      assigns[:users].should == autofollow_list
    end
  end

  describe '#add' do
    it 'adds the user to the autofollow list' do
      user.expects(:add_to_autofollow_list!)
      post :add, user_id: user.id.to_s
      response.should be_jsend_success
      response.jsend_data['alert'].should be
      response.jsend_data['userInfo'].should be
    end

    it 'fails silently when the user is already on the autofollow list' do
      user.expects(:add_to_autofollow_list!).raises(ActiveRecord::RecordNotUnique.new(mock, mock))
      post :add, user_id: user.id.to_s
      response.should be_jsend_success
      response.jsend_data['alert'].should be
      response.jsend_data['userInfo'].should be
    end
  end

  describe '#remove' do
    it 'removes the user from the autofollow list' do
      user.expects(:remove_from_autofollow_list)
      post :remove, user_id: user.id.to_s
      response.should be_jsend_success
      response.jsend_data['alert'].should be
      response.jsend_data['userInfo'].should be
    end
  end

  describe '#reorder' do
    it 'removes the user from the autofollow list' do
      autofollow = stub('autofollow')
      user.stubs(:autofollow).returns(autofollow)
      position = 3
      autofollow.expects(:insert_at).with(position)
      autofollow.expects(:save!)
      post :reorder, user_id: user.id.to_s, position: position.to_s
      response.should be_jsend_success
    end
  end
end
