require 'spec_helper'

describe Listings::Collections do
  describe '::find_liked_not_already_in_owned_collections' do
    let(:user) { FactoryGirl.create(:registered_user) }

    # Listing.liked_by returns a paged AR::Relation of listings that are marked in lagunitas as liked by the user, wo
    # we stub that method to return the listings we want it to.

    it 'returns a liked listing not already in a collection' do
      listing = FactoryGirl.create(:active_listing)
      Listing.stubs(:liked_by).returns(Listing.where(id: listing.id).page(1))
      expect(Listing.find_liked_not_already_in_owned_collections(user)).to eq([listing])
    end

    it 'excludes a liked listing already in a collection' do
      listing = FactoryGirl.create(:active_listing)
      collection = FactoryGirl.create(:collection, user: user)
      collection.add_listing(listing)
      Listing.stubs(:liked_by).returns(Listing.where(id: listing.id).page(1)) # liked_by returns a paged AR::Relation
      expect(Listing.find_liked_not_already_in_owned_collections(user)).to be_empty
    end

    it 'excludes a non-liked listing' do
      listing = FactoryGirl.create(:active_listing)
      Listing.stubs(:liked_by).returns(Listing.where(id: -1).page(1)) # liked_by returns a paged AR::Relation
      expect(Listing.find_liked_not_already_in_owned_collections(user)).to be_empty
    end
  end

  describe '::find_recently_created_from_followed_collections' do
    let(:user) { FactoryGirl.create(:registered_user) }

    it 'returns a listing added to a followed collection' do
      listing = FactoryGirl.create(:active_listing)
      collection = FactoryGirl.create(:collection) # another user's collection
      collection.add_listing(listing)
      user.follow_collection!(collection)
      expect(Listing.find_recently_created_from_followed_collections(user)).to eq([listing])
    end

    it 'excludes listings' do
      listing = FactoryGirl.create(:active_listing)
      collection = FactoryGirl.create(:collection) # another user's collection
      collection.add_listing(listing)
      user.follow_collection!(collection)
      expect(Listing.find_recently_created_from_followed_collections(user, excluded_ids: listing.id)).to be_empty
    end

    it 'excludes listings not in followed collections' do
      listing = FactoryGirl.create(:active_listing)
      expect(Listing.find_recently_created_from_followed_collections(user)).to be_empty
    end

    it 'excludes non-visible listings' do
      listing = FactoryGirl.create(:cancelled_listing)
      collection = FactoryGirl.create(:collection) # another user's collection
      collection.add_listing(listing)
      user.follow_collection!(collection)
      expect(Listing.find_recently_created_from_followed_collections(user)).to be_empty
    end
  end

  describe '::recently_saved_by' do
    let(:user) { FactoryGirl.create(:registered_user) }
    let(:listing) { FactoryGirl.create(:active_listing) }
    let(:collection) { FactoryGirl.create(:collection, user: user) }
    before { collection.add_listing(listing) }

    it 'returns a listing saved to a collection' do
      expect(Listing.recently_saved_by(user)).to have(1).save
    end

    it 'excludes a listing from a seller' do
      expect(Listing.recently_saved_by(user, exclude_sellers: listing.seller)).to be_empty
    end
  end

  describe '::recently_saved_by_ids' do
    let(:user) { FactoryGirl.create(:registered_user) }

    it 'returns a listing saved to a collection' do
      listing = FactoryGirl.create(:active_listing)
      collection = FactoryGirl.create(:collection, user: user)
      collection.add_listing(listing)
      expect(Listing.recently_saved_by_ids(user)).to eq([listing.id])
    end
  end

  describe '#update_collections_for' do
    let(:user) { FactoryGirl.create(:registered_user) }
    let(:listing) { FactoryGirl.create(:active_listing) }
    let(:collections) { FactoryGirl.create_list(:collection, 5, user_id: user.id) }
    let(:other_collection) { FactoryGirl.create(:collection) }
    before do
      (c1, c2, c3, c4, c5) = collections
      user.save_listing_to_collections(listing, [c1, c2, c3])
    end

    it 'updates the collections to which a listing is saved' do
      (c1, c2, c3, c4, c5) = collections
      expect(listing.collections).to eq([c1, c2, c3])
      # just delete collections
      listing.update_collections_for(user, [])
      expect(listing.collections_owned_by(user)).to eq([])
      expect(listing.collections(true)).to eq([])
      # just add collections
      listing.update_collections_for(user, [c1, c3, c5])
      expect(listing.collections_owned_by(user)).to eq([c1, c3, c5])
      # # add and delete collections
      listing.update_collections_for(user, [c2, c3])
      expect(listing.reload.collections).to eq([c2, c3])
    end

    it 'throws an exception if called with a collection not owned by the user' do
      (c1, c2, c3, c4, c5) = collections
      expect { listing.update_collections_for(user, [c1, c4, other_collection]) }.to raise_error(Exception)
    end
  end
end
