require 'spec_helper'

describe Users::RepresentativeListingsPolicy do
  let(:visible_listing) { stub_listing('Pet Rock', id: 1111) }
  let(:invisible_listing) { stub_listing('TIE Fighter', id: 2222) }
  let(:user) { stub_user 'Mott the Hoople' }

  class TestPolicy < Users::RepresentativeListingsPolicy
    def initialize(test_listings_by_user)
      @test_listings_by_user = test_listings_by_user
    end

    def find_candidate_listing_ids(users)
      users.each_with_object({}) { |u, m| m[u.id] = @test_listings_by_user[u.id] }
    end
  end

  subject { TestPolicy.new(user.id => [visible_listing.id, invisible_listing.id]) }

  before do
    Listing.stubs(:visible).returns(stub('visible', all: [visible_listing]))
    ListingPhoto.stubs(:find_primaries).returns(visible_listing.id => visible_listing.photos.first)
    subject.choose!([user])
  end

  describe '.listing' do
    it "should return the visible listing" do
      subject.listing(visible_listing.id).should == visible_listing
    end

    it "should not return the invisible listing" do
      subject.listing(invisible_listing.id).should be_nil
    end
  end

  describe '.listings_for_user' do
    it "should return the visible listing" do
      subject.listings_for_user(user.id).should == [visible_listing]
    end
  end

  describe '.photos_for_user' do
    it "should return the visible listing's photo" do
      subject.photos_for_user(user.id).should == [visible_listing.photos.first]
    end
  end
end
