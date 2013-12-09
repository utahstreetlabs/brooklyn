require 'spec_helper'

describe Collections::Autofollowable do
  subject { FactoryGirl.create(:collection) }

  describe '.autofollowed_for_interest?' do
    let(:interest) { FactoryGirl.create(:interest) }

    context 'when the collection is on the autofollowed interest list' do
      before { FactoryGirl.create(:collection_autofollow, collection: subject, interest: interest) }
      it 'returns true' do
        subject.autofollowed_for_interest?(interest).should be_true
      end
    end

    context 'when the collection is not on the autofollowed interest list' do
      it 'returns false' do
        subject.autofollowed_for_interest?(interest).should be_false
      end
    end
  end

  describe '.autofollowed?' do
    let(:interest) { FactoryGirl.create(:interest) }

    context 'when the collection is autofollowed' do
      before { FactoryGirl.create(:collection_autofollow, collection: subject, interest: interest) }
      it 'returns true' do
        subject.autofollowed?.should be_true
      end
    end

    context 'when the collection is not autofollowed' do
      it 'returns false' do
        subject.autofollowed?.should be_false
      end
    end
  end

end
