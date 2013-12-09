require 'spec_helper'

describe Collection do
  it "should allow at most #{Collection::MAX_COLLECTIONS} collections per user" do
    user = FactoryGirl.create(:registered_user)
    FactoryGirl.create_list(:collection, Collection::MAX_COLLECTIONS - Collection::default_collection_specs.count,
                            user: user)
    expect { FactoryGirl.create(:collection, name: 'ASPLODE', user: user) }.
      to raise_error
  end

  it 'should not allow name changes if it is not editable' do
    collection = FactoryGirl.create(:collection, name: "U Can't Touch This.", editable: false)
    collection.name = 'I touched it'
    expect { collection.save }.to raise_exception
  end

  it 'should allow creating two collections whose names differ only in punctuation' do
    user = FactoryGirl.create(:registered_user)
    expect(FactoryGirl.create(:collection, user: user, name: "Ham products.")).to be_persisted
    expect(FactoryGirl.create(:collection, user: user, name: "Ham products")).to be_persisted
  end

  it 'should allow name changes if it is editable, the default' do
    collection = FactoryGirl.create(:collection, name: "U Can Touch This")
    collection.name = 'I touched it'
    expect(collection.save).to be_true
  end

  it 'assigns a type code if one is not specified' do
    collection = FactoryGirl.create(:collection)
    expect(collection.type_code).to eq(Collection::Types::GENERIC)
  end

  it 'does not assign a type code if one is specified' do
    collection = FactoryGirl.create(:collection, type_code: Collection::Types::HAVE)
    expect(collection.type_code).to eq(Collection::Types::HAVE)
  end

  it 'should be followed by its creator' do
    collection = FactoryGirl.create(:collection)
    expect(collection.user.following_collection?(collection)).to be_true
  end

  describe '#create_defaults_for' do
    it 'creates default collections appropriately' do
      user = FactoryGirl.create(:registered_user)
      expect(user.collections).to have(Collection.default_collection_specs.size).entries
      Collection.default_collection_specs.each do |spec|
        collection = user.collections.where(slug: spec[:slug]).first
        expect(collection).to be
        expect(collection.name).to eq(spec[:name])
        expect(collection.type_code).to eq(spec[:type_code])
        expect(collection.editable).to eq(spec[:editable])
      end
    end
  end

  describe '.type' do
    it 'returns the appropriate type name' do
      expect(Collection.new(type_code: Collection::Types::HAVE).type).to eq(:have)
    end
  end

  describe 'type predicate' do
    it 'returns whether or not the collection is of a certain type' do
      collection = Collection.new(type_code: Collection::Types::HAVE)
      expect(collection).to be_have
      expect(collection).to_not be_generic
    end
  end

  describe '.add_listings' do
    it 'adds all listings' do
      listings = FactoryGirl.create_list(:active_listing, 2)
      collection = FactoryGirl.create(:collection)
      collection.add_listings(listings.map(&:id))
      expect(collection.listings.reload).to eq(listings)
    end
  end

  describe '#find_named_for_user' do
    it 'finds the named collection' do
      collection = FactoryGirl.create(:collection)
      expect(Collection.find_named_for_user(collection.name, collection.owner)).to eq(collection)
    end
  end

  describe '#listing_count' do
    it 'correctly reflects the number of listings in this collection' do
      listing = FactoryGirl.create(:active_listing)
      collection = FactoryGirl.create(:collection)
      collection.add_listing(listing)
      expect(collection.reload.listing_count).to eq(1)
    end

    it 'gets reset if it is nil' do
      listing = FactoryGirl.create(:active_listing)
      collection = FactoryGirl.create(:collection)
      collection.add_listing(listing)
      # bypass validations, readonly, etc
      ActiveRecord::Base.connection.execute("UPDATE collections SET listing_count=NULL WHERE id=#{collection.id}")
      expect(collection.reload.listing_count).to eq(1)
    end
  end

  describe '#follower_count' do
    it 'correctly reflects the number of followers of this collection' do
      collection = FactoryGirl.create(:collection)
      user = FactoryGirl.create(:registered_user)
      user.follow_collection!(collection)
      expect(collection.reload.follower_count).to eq(2)
    end
  end

  it 'should reset its slug when its name is changed' do
    collection = FactoryGirl.create(:collection, name: 'awesome stuff')
    expect(collection.slug).to eq('awesome-stuff')
    collection.name = 'franken berry'
    collection.save!
    expect(collection.slug).to eq('franken-berry')
  end

  it 'should not reset its slug if the collection is not editable' do
    collection = FactoryGirl.create(:collection, name: 'awesome stuff', slug: 'rad', editable: false)
    expect(collection.slug).to eq('rad')
    collection.name = 'franken berry'
    expect { collection.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect(collection.slug).to eq('rad')
  end

  describe '::find_most_followed' do
    it 'returns followed collections in descending order of follow count' do
      users = FactoryGirl.create_list(:registered_user, 2) # autocreates collections
      users.second.follow_collection!(users.first.collections.first)
      rv = Collection.find_most_followed.to_a # AR-generated count query doesn't work
      expect(rv.first).to eq(users.first.collections.first)
      expect(rv.size).to eq(users.inject(0) { |sum, u| sum + u.collections.size })
    end

    it 'only considers follows from the provided window' do
      user = FactoryGirl.create(:registered_user) # autocreates collections
      Timecop.travel(2.weeks.from_now) do
        rv = Collection.find_most_followed(window: 1.week).to_a # AR-generated count query doesn't work
        expect(rv).to be_empty
      end
    end

    it 'only considers collections with a minimum number of listings' do
      users = FactoryGirl.create_list(:registered_user, 2) # autocreates collections
      listings = FactoryGirl.create_list(:active_listing, 2)
      users.first.collections.first.add_listings(listings.map(&:id))
      users.first.collections.first.reload
      users.second.follow_collection!(users.first.collections.first)
      rv = Collection.find_most_followed(min_listings: 2).to_a # AR-generated count query doesn't work
      expect(rv.first).to eq(users.first.collections.first)
      expect(rv.size).to eq(1)
    end

    it 'excludes collections owned by the provided user' do
      users = FactoryGirl.create_list(:registered_user, 2) # autocreates collections
      rv = Collection.find_most_followed(exclude_owners: users.first).to_a # AR-generated count query doesn't work
      expect(rv.size).to eq(users.second.collections.size)
    end
  end
end
