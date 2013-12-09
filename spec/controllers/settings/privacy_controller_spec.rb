require 'spec_helper'

describe Settings::PrivacyController do
  if feature_enabled?(:feedback)
    describe '#update' do
      before { act_as_stub_user }

      context 'when the params are invalid' do
        before { Settings::PrivacyController::Privacy.any_instance.stubs(:valid?).returns(false) }

        it 're-renders with inline errors' do
          put :update, privacy: {purchase_details: 'true'}
          flash.should be_empty
          response.should render_template(:show)
        end
      end

      context 'when the save fails' do
        before do
          Settings::PrivacyController::Privacy.any_instance.stubs(:valid?).returns(true)
          subject.send(:current_user).stubs(:save_privacy_prefs).returns(nil)
        end

        it 're-renders with a flash alert' do
          put :update, privacy: {purchase_details: 'true'}
          flash[:alert].should be
          response.should render_template(:show)
        end
      end

      context 'when the save succeeds' do
        before do
          Settings::PrivacyController::Privacy.any_instance.stubs(:valid?).returns(true)
          subject.send(:current_user).stubs(:save_privacy_prefs).returns(mock)
        end

        it 'redirects with a flash notice' do
          put :update, privacy: {purchase_details: 'true'}
          flash[:notice].should be
          response.should redirect_to(settings_privacy_path)
        end
      end
    end
  end

  describe 'Privacy#create_with_defaults' do
    context 'when there is a stored pref' do
      subject { Settings::PrivacyController::Privacy.create_with_defaults(purchase_details: true) }
      its(:purchase_details) { should be_true }
    end

    context 'when there is no stored pref' do
      subject { Settings::PrivacyController::Privacy.create_with_defaults({}) }
      its(:purchase_details) { should be_false }
    end

    context 'when the prefs are nil' do
      subject { Settings::PrivacyController::Privacy.create_with_defaults(nil) }
      its(:purchase_details) { should be_true }
    end
  end
end
