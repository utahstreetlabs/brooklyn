require 'spec_helper'

describe HotOrNotService do
  let(:user) { FactoryGirl.create(:registered_user) }
  subject { HotOrNotService.new(user) }

  describe '.hot_or_not_suggestions' do
    let(:listing) { FactoryGirl.create(:active_listing) }

    context 'when a user does not have enough likes to select more via clustering' do
      before do
        Pyramid::User::Likes.expects(:count).with(user.id, is_a(Hash)).
          returns(HotOrNotService.config.likes_needed_for_custom - 1)
      end

      it 'gets returns trending listings' do
        Pyramid::Likeable::Likes.expects(:recent).returns([listing.id])
        expect(subject.suggestions).to eq([listing])
      end
    end

    context 'when a user has enough likes to select more via clustering' do
      let(:suggestions) { [listing.id] }
      before do
        Pyramid::User::Likes.expects(:count).with(user.id, is_a(Hash)).
          returns(HotOrNotService.config.likes_needed_for_custom)
        Pyramid::User.expects(:hot_or_not_suggestions).with(user.id).returns(suggestions)
      end

      context 'when the suggestion is not disliked' do
        it 'returns the suggestion' do
          expect(subject.suggestions).to eq([listing])
        end
      end

      context 'when the suggestion is disliked' do
        before { user.dislike(listing) }
        it 'does not return the suggestion' do
          expect(subject.suggestions).to be_empty
        end
      end
    end
  end
end
