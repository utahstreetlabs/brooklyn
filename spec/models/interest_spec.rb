require 'spec_helper'

describe Interest do
  describe 'validation' do
    subject { FactoryGirl.build(:interest) }

    context 'when name is blank' do
      before { subject.name = nil }
      it { should_not be_valid }
    end

    context 'when name is a duplicate' do
      before { FactoryGirl.create(:interest, name: subject.name) }
      it { should_not be_valid }
    end

    context 'when name is a differently cased duplicate' do
      before { FactoryGirl.create(:interest, name: subject.name.upcase) }
      it { should_not be_valid }
    end

    context 'when cover photo is blank' do
      before { subject.remove_cover_photo! }
      it { should_not be_valid }
    end

    context 'when onboarding is blank' do
      before { subject.onboarding = nil }
      it { should_not be_valid }
    end
  end

  describe '.add_to_suggested_user_list!' do
    subject { FactoryGirl.create(:interest) }
    let(:user) { FactoryGirl.create(:registered_user) }

    context 'when the user is not already in the list' do
      it 'adds the user to the list' do
        subject.add_to_suggested_user_list!(user)
        subject.suggestions.where(user_id: user.id).count.should == 1
      end
    end

    context 'when the user is already in the list' do
      before { FactoryGirl.create(:user_suggestion, interest: subject, user: user) }
        it 'raises ActiveRecord::RecordNotUnique' do
        expect { subject.add_to_suggested_user_list!(user) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  describe '.move_within_suggested_user_list!' do
    subject { FactoryGirl.create(:interest) }
    let(:user) { FactoryGirl.create(:registered_user) }

    context 'when the user is already in the list' do
      before { FactoryGirl.create(:user_suggestion, interest: subject, user: user, position: 1) }

      it 'repositions the user within the list' do
        subject.move_within_suggested_user_list!(user, 2)
        subject.suggestions.where(user_id: user.id).first.position.should == 2
      end
    end

    context "when the user is not already in the list" do
      it 'raises ActiveRecord::RecordNotFound' do
        expect { subject.move_within_suggested_user_list!(user, 2) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '.remove_from_suggested_user_list' do
    subject { FactoryGirl.create(:interest) }
    let(:user) { FactoryGirl.create(:registered_user) }

    context 'when the user is in the list' do
      before { FactoryGirl.create(:user_suggestion, interest: subject, user: user) }

      it 'removes the user from the list' do
        subject.remove_from_suggested_user_list(user)
        subject.suggestions.where(user_id: user.id).should be_empty
      end
    end

    context "when the user is not already in the list" do
      it 'does nothing' do
        subject.remove_from_suggested_user_list(user)
        subject.suggestions.where(user_id: user.id).should be_empty
      end
    end
  end

  describe '.in_suggested_user_list?' do
    subject { FactoryGirl.create(:interest) }
    let(:user) { FactoryGirl.create(:registered_user) }

    context 'when the user is in the list' do
      before { FactoryGirl.create(:user_suggestion, interest: subject, user: user) }

      it 'returns true' do
        subject.in_suggested_user_list?(user).should be_true
      end
    end

    context "when the user is not already in the list" do
      it 'returns false' do
        subject.in_suggested_user_list?(user).should be_false
      end
    end
  end

  describe '.move_within_onboarding_list!' do
    subject { FactoryGirl.create(:interest, onboarding: true) }

    it 'repositions the user within the list' do
      subject.move_within_onboarding_list!(2)
      subject.reload
      subject.position.should == 2
    end
  end

  describe '.remove_from_onboarding_list!' do
    subject { FactoryGirl.create(:interest, onboarding: true) }

    it 'removes the user from the list' do
      subject.remove_from_onboarding_list!
      subject.reload
      subject.onboarding.should be_false
    end
  end

  describe '.destroy' do
    subject { FactoryGirl.create(:interest) }

    it 'destroys associatd suggestions' do
      FactoryGirl.create(:user_suggestion, interest: subject)
      subject.destroy
      subject.suggestions.should be_empty
    end

    it 'destroys associated user interests' do
      FactoryGirl.create(:user_interest, interest_id: subject.id)
      subject.destroy
      subject.user_interests.should be_empty
    end
  end

  describe '#global' do
    before { FactoryGirl.create(:global_interest) }

    it 'returns the global interest' do
      Interest.global.id.should == -1
    end
  end

  describe '#add_to_onboarding_list!' do
    before { FactoryGirl.create(:global_interest) }
    let(:interests) { FactoryGirl.create_list(:interest, 3) }

    it 'adds each interest to the list' do
      Interest.add_to_onboarding_list!((interests + [Interest.global]).map(&:id))
      interests.each { |i| i.reload; i.onboarding.should be_true }
      Interest.global.reload
      Interest.global.onboarding.should be_false
    end
  end

  describe '#remove_from_onboarding_list!' do
    let(:interests) { FactoryGirl.create_list(:interest, 3, onboarding: true) }

    it 'removes each interest from the list' do
      Interest.remove_from_onboarding_list!(interests.map(&:id))
      interests.each { |i| i.reload; i.onboarding.should be_false }
    end
  end

  describe '#listings' do
    subject { FactoryGirl.create(:interest) }
    let!(:listing_not_in_collection) { FactoryGirl.create(:active_listing) }
    let!(:listing) { FactoryGirl.create(:active_listing) }
    let!(:collection) { FactoryGirl.create(:collection) }
    before do
      collection.add_listing(listing)
      collection.autofollow_for_interests!([subject.id])
    end

    it 'should return listings in autofollow collections' do
      expect(subject.listings).to eq([listing])
    end
  end
end
