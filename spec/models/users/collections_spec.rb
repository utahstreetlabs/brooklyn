require 'spec_helper'

describe Users::Collections do
  describe '#save_listing_to_collections' do
    let!(:user) { FactoryGirl.create(:registered_user) }
    let!(:listing) { FactoryGirl.create(:active_listing) }

    it 'adds the listing to each collection' do
      collections = FactoryGirl.create_list(:collection, 2, user: user)
      user.save_listing_to_collections(listing, collections)
      collections.each do |collection|
        expect(collection.listings.reload).to include(listing)
      end
    end
  end

  describe '#unowned_collection_follows' do
    it 'excludes follow of an owned collection' do
      user = FactoryGirl.create(:registered_user)
      user.follow_collection!(FactoryGirl.create(:collection, user: user))
      user.follow_collection!(FactoryGirl.create(:collection))
      expect(user.unowned_collection_follows).to have(1).follow
    end
  end

  describe '#unowned_collection_follows_count' do
    it 'excludes follow of an owned collection' do
      user = FactoryGirl.create(:registered_user)
      user.follow_collection!(FactoryGirl.create(:collection, user: user))
      user.follow_collection!(FactoryGirl.create(:collection))
      expect(user.unowned_collection_follows_count).to eq(1)
    end
  end
end
