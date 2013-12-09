require 'spec_helper'

describe Likeable do
  class Fnord
    include Likeable

    def self.logger
      Rails.logger
    end
  end

  subject do
    fnord = Fnord.new
    fnord.stubs(:id).returns(43)
    fnord.stubs(:logger).returns(stub_everything)
    fnord
  end

  describe '.likes_count' do
    it 'calls Pyramid::Likeable::Likes#count and returns the count' do
      count = mock
      Pyramid::Likeable::Likes.expects(:count).with(subject.id, subject.likeable_type, is_a(Hash)).returns(count)
      subject.likes_count.should == count
    end
  end

  describe '.likes_summary' do
    it 'calls Pyramid::Likeable::Likes#summary and returns the summary' do
      summary = mock
      Pyramid::Likeable::Likes.expects(:summary).with(subject.id, subject.likeable_type, is_a(Hash)).returns(summary)
      subject.likes_summary.should == summary
    end
  end

  it 'has a likeable type' do
    subject.likeable_type.should == :fnord
  end

  it 'has a likeable id attribute' do
    subject.likeable_id_attr.should == :fnord_id
  end

  describe '::liked_by' do
    let(:user) { FactoryGirl.create(:registered_user) }

    context "when the user has liked visible listings" do
      let(:listings) { FactoryGirl.create_list(:active_listing, 2) }

      before do
        user.stubs(:likes).returns(listings.reverse.map { |l| stub("like-#{l.id}", listing_id: l.id) })
      end

      it "returns the first page of listings" do
        rv = Listing.liked_by(user, per: 1)
        expect(rv).to include(listings.first)
        expect(rv).to_not include(listings.second)
        expect(rv.size).to eq(1)
        expect(rv.total_count).to eq(2)
      end

      it "returns the first page of listings, excluding one" do
        rv = Listing.liked_by(user, per: 1, excluded_ids: listings.first.id)
        expect(rv).to_not include(listings.first)
        expect(rv).to include(listings.second)
        expect(rv.size).to eq(1)
        expect(rv.total_count).to eq(1)
      end

      it "returns the first page of listings, excluding those from a seller" do
        rv = Listing.liked_by(user, per: 1, exclude_sellers: listings.first.seller)
        expect(rv).to_not include(listings.first)
        expect(rv).to include(listings.second)
        expect(rv.size).to eq(1)
        expect(rv.total_count).to eq(1)
      end

      it "returns the first page of listings in exact order" do
        rv = Listing.liked_by(user, exact_order: true)
        expect(rv).to eq([listings.second, listings.first])
        expect(rv.total_count).to eq(2)
      end
    end

    context "when the user has liked an invisible listing" do
      let(:listing) { FactoryGirl.create(:suspended_listing) }

      before do
        user.stubs(:likes).returns([stub("like-#{listing.id}", listing_id: listing.id)])
      end

      it "returns an empty page of listings" do
        rv = Listing.liked_by(user, per: 1)
        expect(rv).to be_empty
        expect(rv.total_count).to eq(0)
      end
    end

    context "when the user has not liked any listings" do
      before do
        user.stubs(:likes).returns([])
      end

      it "returns no listings" do
        expect(Listing.liked_by(user, per: 1)).to be_empty
      end
    end
  end

  describe '::liked_by_ids' do
    let(:user) { FactoryGirl.create(:registered_user) }

    context "when the user has liked listings" do
      let(:listings) { FactoryGirl.create_list(:active_listing, 2) }

      before do
        user.stubs(:likes).returns(listings.reverse.map { |l| stub("like-#{l.id}", listing_id: l.id) })
      end

      it "returns the ids" do
        rv = Listing.liked_by_ids(user)
        expect(rv).to include(listings.first.id)
        expect(rv).to include(listings.second.id)
        expect(rv.size).to eq(2)
      end
    end

    context "when the user has not liked any listings" do
      before do
        user.stubs(:likes).returns([])
      end

      it "returns no ids" do
        expect(Listing.liked_by_ids(user)).to be_empty
      end
    end
  end

  describe '#like_visible' do
    it "returns an AR scope for the specified likeables which are like visible" do
      ids = [123, 456]
      scope = stub('scope')
      subject.class.expects(:where).with(has_entries(id: ids)).returns(scope)
      subject.class.like_visible(ids).should == scope
    end
  end
end
