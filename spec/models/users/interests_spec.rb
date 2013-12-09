require 'spec_helper'

describe Users::Interests do
  subject { FactoryGirl.create(:registered_user) }

  describe 'active record wrappers' do
    let!(:listing) { FactoryGirl.create(:active_listing) }
    let!(:interest) { FactoryGirl.create(:interest) }
    let!(:collection) { FactoryGirl.create(:collection) }
    before do
      collection.add_listing(listing)
      collection.autofollow_for_interests!([interest.id])
    end

    describe '#liked_in_interest' do
      let!(:listing_not_in_collection) { FactoryGirl.create(:active_listing) }
      let(:likes) { [] }
      before do
        subject.expects(:likes).returns(likes)
      end

      context 'when the listing is liked' do
        let(:likes) { [stub(listing_id: listing.id)] }
        it 'should return liked listings' do
          expect(subject.liked_in_interest(interest)).to eq([listing])
        end
      end

      context 'when the listing is not liked' do
        let(:likes) { [] }
        it 'should return 0' do
          expect(subject.liked_in_interest(interest)).to eq([])
        end
      end
    end

    describe '#dislikes_in_interest_count' do
      context 'when the listing is disliked' do
        let!(:dislike) { FactoryGirl.create(:dislike, user: subject, listing: listing) }
        it 'should return 1' do
          expect(subject.dislikes_in_interest(interest).count).to eq(1)
        end
      end

      it 'should return 0' do
        expect(subject.dislikes_in_interest(interest).count).to eq(0)
      end
    end
  end

  describe '#interest_score' do
    let(:interest) { stub('interest') }
    let(:like_count) {}
    let(:liked) { stub('likes', count: like_count) }
    let(:dislike_count) {}
    let(:dislikes) { stub('dislikes', count: dislike_count) }
    before do
      subject.expects(:liked_in_interest).with(interest, {}).returns(liked)
      subject.expects(:dislikes_in_interest).with(interest).returns(dislikes)
    end

    context 'when likes and dislikes are both 0' do
      let(:like_count) { 0 }
      let(:dislike_count) { 0 }
      it 'returns 0' do
        expect(subject.interest_score(interest)).to eq(0)
      end
    end

    context 'when dislikes are 0' do
      let(:like_count) { 5 }
      let(:dislike_count) { 0 }
      it 'returns 1' do
        expect(subject.interest_score(interest)).to eq(1)
      end
    end

    context 'when like and dislike counts are both positive integers' do
      let(:like_count) { 2 }
      let(:dislike_count) { 2 }
      it 'returns (likes / (likes + dislikes)' do
        expect(subject.interest_score(interest)).to eq(0.5)
      end
    end
  end

  describe '#interest_scores' do
    let(:likes) { [] }
    let(:interest1) { stub('interest 1') }
    let(:interest2) { stub('interest 2') }

    it 'calculates an interest score for each interest' do
      Interest.expects(:all_but_global).returns([interest1, interest2])
      subject.expects(:likes).returns(likes)
      subject.expects(:interest_score).with(interest1, likes: likes).returns(1)
      subject.expects(:interest_score).with(interest2, likes: likes).returns(2)
      expect(subject.interest_scores).to eq({interest1 => 1, interest2 => 2})
    end
  end
end
