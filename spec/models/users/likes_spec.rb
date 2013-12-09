require 'spec_helper'

describe Users::Likes do
  class LikingUser
    include Users::Likes
  end

  before { LikingUser.stubs(:logger).returns(stub_everything) }

  subject do
    u = LikingUser.new
    u.stubs(:id).returns(87)
    u.stubs(:logger).returns(stub_everything)
    u
  end

  let(:likeable_type) { :nug }
  let(:likeable) { stub('likeable', likeable_type: likeable_type, id: 123) }

  describe '.likes' do
    it 'calls Pyramid::User::Likes#find and returns its result' do
      likes = mock
      Pyramid::User::Likes.expects(:find).with(subject.id, is_a(Hash)).returns(likes)
      subject.likes.should == likes
    end
  end

  describe '.likes_count' do
    it 'calls Pyramid::User::Likes#count and returns its result' do
      count = mock
      Pyramid::User::Likes.expects(:count).with(subject.id, is_a(Hash)).returns(count)
      subject.likes_count.should == count
    end
  end

  describe '.liked' do
    it 'returns a paged array of likeables' do
      l1 = FactoryGirl.create(:active_listing)
      l2 = FactoryGirl.create(:inactive_listing)
      t1 = FactoryGirl.create(:tag)
      likes = [
        stub(listing_id: l1.id, tag_id: nil),
        stub(listing_id: l2.id, tag_id: nil),
        stub(listing_id: nil, tag_id: t1.id)
      ]
      paged = Ladon::PaginatableArray.new(likes, offset: 1, limit: 1, total: 3)
      subject.expects(:likes).returns(paged)
      likeables = subject.liked
      likeables.total_count.should == paged.total_count
      likeables.offset_value.should == paged.offset_value
      likeables.limit_value.should == paged.limit_value
      likeables.should == [l1, t1]
    end
  end

  describe '.like_for' do
    it 'calls Pyramid::User::Likes#get and returns the like' do
      like = stub('like')
      Pyramid::User::Likes.expects(:get).with(subject.id, likeable.likeable_type, likeable.id, is_a(Hash)).
        returns(like)
      subject.like_for(likeable).should == like
    end
  end

  describe '.likes?' do
    it 'calls Pyramid::User::Likes#get and returns true when the user likes the likeable' do
      subject.expects(:like_for).with(likeable, is_a(Hash)).returns(mock)
      subject.likes?(likeable).should be_true
    end

    it 'calls Pyramid::User::Likes#get and returns false when the user does not like the likeable' do
      subject.expects(:like_for).with(likeable, is_a(Hash)).returns(nil)
      subject.likes?(likeable).should be_false
    end
  end

  describe '.like_existences' do
    it 'calls Pyramid::User::Likes#existences and returns its result' do
      likeable_ids = stub('likeable-ids')
      existences = stub('existences')
      Pyramid::User::Likes.expects(:existences).with(subject.id, likeable_type, likeable_ids, is_a(Hash)).
        returns(existences)
      subject.like_existences(likeable_type, likeable_ids)
    end
  end

  describe '.like' do
    it 'calls Pyramid::User::Likes#create, notifies observers and returns the new like' do
      like = stub
      Pyramid::User::Likes.expects(:create).with(subject.id, likeable.likeable_type, likeable.id, is_a(Hash)).
        returns(like)
      likeable.expects(:notify_observers).with(:after_like, subject, like, is_a(Hash))
      subject.like(likeable).should == like
    end

    it 'calls Pyramid::User::Likes#create, does not notify observers and returns nil when there is an error' do
      Pyramid::User::Likes.expects(:create).with(subject.id, likeable.likeable_type, likeable.id, is_a(Hash)).
        returns(nil)
      likeable.expects(:notify_observers).never
      subject.like(likeable).should be_nil
    end
  end

  describe '.unlike' do
    it 'calls Pyramid::User::Likes#destroy and notifies observers' do
      Pyramid::User::Likes.expects(:destroy).with(subject.id, likeable.likeable_type, likeable.id, is_a(Hash))
      likeable.expects(:notify_observers).with(:after_unlike, subject, is_a(Hash))
      subject.unlike(likeable)
    end
  end

  describe '#like_counts' do
    it 'calls Pyramid::User::Likes#count_many and returns its result' do
      ids = [123, 456]
      counts = stub
      Pyramid::User::Likes.expects(:count_many).with(ids, is_a(Hash)).returns(counts)
      subject.class.like_counts(ids).should == counts
    end
  end
end
