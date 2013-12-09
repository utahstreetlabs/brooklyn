require 'spec_helper'

describe Users::Suggestable do
  subject { FactoryGirl.create(:registered_user) }

  describe '.suggested_for_interest?' do
    let(:interest) { FactoryGirl.create(:interest) }

    context 'when the user is on the suggested user list' do
      before { FactoryGirl.create(:user_suggestion, user: subject, interest: interest) }
      it 'returns true' do
        subject.suggested_for_interest?(interest).should be_true
      end
    end

    context 'when the user is not on the suggested user list' do
      it 'returns false' do
        subject.suggested_for_interest?(interest).should be_false
      end
    end
  end
end
