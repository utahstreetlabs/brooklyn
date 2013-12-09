require 'spec_helper'

describe ListingListSnapshot do
  let(:redis) { stub('redis connection') }
  before { ListingListSnapshot.redis = redis }

  describe '::find_for_timestamp' do
    let(:latest_timestamp) { 123456789 }
    let(:latest_key) { "featurable:snapshot:slug:#{latest_timestamp}" }
    let(:missing_timestamp) { 987654321 }
    let(:missing_key) { "featurable:snapshot:slug:#{missing_timestamp}" }

    context 'with a valid timestamp' do
      before { redis.expects(:exists).with(latest_key).returns(true) }

      it 'stores the timestamp and appropriate key' do
        fs = ListingListSnapshot.find_for_timestamp('featurable:snapshot:slug', latest_timestamp)
        expect(fs.timestamp).to eq(latest_timestamp)
        expect(fs.key).to eq(latest_key)
      end
    end

    context 'with no timestamp' do
      before { redis.expects(:keys).returns([latest_key]) }

      it 'stores the latest timestamp and apprapriate key' do
        fs = ListingListSnapshot.find_for_timestamp('featurable:snapshot:slug', nil)
        expect(fs.timestamp).to eq(latest_timestamp)
        expect(fs.key).to eq(latest_key)
      end
    end

    context 'with a missing timestamp' do
      before do
        redis.expects(:exists).with(missing_key).returns(false)
        redis.expects(:keys).returns([latest_key])
      end

      it 'stores the latest timestamp and appropriate key' do
        fs = ListingListSnapshot.find_for_timestamp('featurable:snapshot:slug', missing_timestamp)
        expect(fs.timestamp).to eq(latest_timestamp)
        expect(fs.key).to eq(latest_key)
      end
    end
  end

  describe '#build!' do
    let(:listing_ids) { (1..10).to_a }
    let(:snapshot) { ListingListSnapshot.new('slug', 123456789) }

    it 'stores all listing ids sorted by recent likes, including those with no likes' do
      redis.expects(:rpush).with(snapshot.key, listing_ids)
      snapshot.build!(listing_ids)
    end
  end

  describe '#listings' do
    let(:key) { 'featurable:snapshot:slug:123' }
    let(:listing) { Factory.create(:active_listing) }
    let(:encoded) { listing.id.to_s }
    before do
      redis.stubs(:exists).returns(true)
      redis.expects(:lrange).with(key, 0, 35).returns([encoded])
      redis.expects(:llen).with(key).returns(1)
    end

    it 'returns a paginatable array with the listings in it' do
      fs = ListingListSnapshot.new('featurable:snapshot:slug', 123)
      listings = fs.listings
      expect(listings.first).to eq(listing)
      expect(listings.count).to eq(1)
    end
  end

  describe '#delete_old_keys!' do
    let(:slug) { 'featurable:snapshot:slug' }
    let(:keys) { (1..4).map { |i| "#{slug}:12345678#{i}" } }

    before do
      redis.expects(:keys).with("#{slug}:*").returns(keys)
    end

    it 'deletes all keys other than the most recent' do
      redis.expects(:del).with(keys.first)
      ListingListSnapshot.delete_old_keys!(slug, 3)
    end

    it "doesn't delete keys if there aren't enough" do
      redis.expects(:del).never
      ListingListSnapshot.delete_old_keys!(slug, 6)
    end
  end
end
