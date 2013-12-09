require 'spec_helper'

class KVStashUser < StashingUser
  include Users::KeyValueStash
end

describe Users::KeyValueStash do
  subject { KVStashUser.new }
  let(:stash) { subject.stash }
  let(:redis) { stub('redis') }
  let(:seconds) { 300 }

  before do
    redis.stubs(:multi).yields(nil)
    subject.class.redis = redis
  end

  describe '#touch_last_accessed' do
    it 'sets last accessed key and updates stash expiration' do
      stash.expects(:expire)
      subject.touch_last_accessed
      stash[subject.class::LAST_ACCESSED_KEY].should be
    end
  end

  describe '#last_accessed' do
    it 'returns last accessed value' do
      timestamp = Time.now.utc
      stash[subject.class::LAST_ACCESSED_KEY] = timestamp
      subject.last_accessed.should == timestamp.to_s
    end
  end

  describe '#touch_last_synced' do
    it 'sets synced key' do
      subject.touch_last_synced
      stash[subject.class::LAST_SYNCED_KEY].should be
    end
  end

  describe '#last_synced' do
    it 'returns last synced value' do
      timestamp = Time.now.utc
      stash[subject.class::LAST_SYNCED_KEY] = timestamp
      subject.last_synced.should == timestamp.to_s
    end
  end

  describe '#clear_stash' do
    it 'clears the stash' do
      stash.expects(:clear)
      subject.clear_stash
    end
  end

  describe '#delete_inactive_stashes!' do
    it 'deletes each inactive stash' do
      keys = (1..5).map {|n| n.to_s}
      subject.class.stubs(:find_stash_keys_for_stale_timestamp).with(subject.class::LAST_ACCESSED_KEY, seconds).
        returns(keys)
      keys.each {|key| redis.expects(:del).with(key).returns(1)}
      subject.class.delete_inactive_stashes!(seconds).should == keys.size
    end
  end

  describe '#unsynced' do
    it 'returns users with stale last synced value' do
      users = mock
      subject.class.stubs(:with_stale_stash_timestamp).with(subject.class::LAST_SYNCED_KEY, seconds).returns(users)
      subject.class.unsynced(seconds).should == users
    end
  end

  describe '#each_unsynced_after_deleting_inactive' do
    let(:keys) { ['user:1:stash', 'user:2:stash'] }
    let(:user) { stub('user') }

    it 'yields only unsynced values that are still active' do
      subject.class.stubs(:stash_keys).returns(keys)
      subject.class.redis.expects(:hmget).with(keys.first, subject.class::LAST_ACCESSED_KEY,
        subject.class::LAST_SYNCED_KEY).returns([nil, Time.now.to_s])
      subject.class.redis.expects(:del).with(keys.first)
      subject.class.redis.expects(:hmget).with(keys.last, subject.class::LAST_ACCESSED_KEY,
        subject.class::LAST_SYNCED_KEY).returns([30.minutes.ago.to_s, 20.minutes.ago.to_s])
      subject.class.expects(:find).with(2).returns
      subject.class.each_unsynced_after_deleting_inactive(30) {|u| u.should == user}
    end
  end

  describe '#with_stale_stash_timestamp' do
    it 'returns users with stale attribute values' do
      attribute_key = 'slurm'
      ids = (1..5)
      keys = ids.map {|n| redis_key(n, attribute_key)}
      users = mock
      subject.class.stubs(:find_stash_keys_for_stale_timestamp).with(attribute_key, seconds).returns(keys)
      subject.class.stubs(:where).with(id: ids.to_a).returns(users)
      subject.class.with_stale_stash_timestamp(attribute_key, seconds).should == users
    end
  end

  describe '#find_stash_keys_for_stale_timestamp' do
    it 'returns only keys for stale attributes' do
      attribute_key = 'slurm'
      ids = (1..2)
      keys = ids.map {|n| redis_key(n, attribute_key)}
      values = keys.map {|key| mock}
      subject.class.stubs(:stash_keys).returns(keys)
      keys.each_with_index {|key, i| redis.stubs(:hget).with(key, attribute_key).returns(values[i])}
      subject.class.stubs(:stale_timestamp?).with(values[0], seconds).returns(true)
      subject.class.stubs(:stale_timestamp?).with(values[1], seconds).returns(false)
      subject.class.find_stash_keys_for_stale_timestamp(attribute_key, seconds).should == [keys[0]]
    end
  end

  describe '#stash_keys' do
    it 'returns the stash keys for the class' do
      keys = mock
      redis.expects(:keys).with("#{subject.class.redis_prefix}:*:stash").returns(keys)
      subject.class.stash_keys.should == keys
    end
  end

  describe '#stale_timestamp?' do
    it 'returns true when the value is blank' do
      subject.class.stale_timestamp?(nil, seconds).should be_true
    end

    it 'returns true when the value is too old' do
      timestamp = subject.class.to_timestamp(24.hours.ago)
      subject.class.stale_timestamp?(timestamp, seconds).should be_true
    end

    it 'returns false when the value is not too old' do
      timestamp = subject.class.to_timestamp(5.seconds.ago)
      subject.class.stale_timestamp?(timestamp, seconds).should be_false
    end
  end

  describe '#last_feed_refresh_time' do
    let(:key) { redis_key(subject.id, :last_feed_refresh) }
    let(:time) { Time.zone.now }
    it 'stores the current time if none set' do
      Timecop.freeze(time) do
        subject.last_feed_refresh_time.should == time
        subject.last_feed_refresh.value.should == subject.class.to_timestamp(time.utc)
      end
    end
  end

  def redis_key(id, attribute_key)
    "#{subject.class.redis_prefix}:#{id}:#{attribute_key}"
  end
end
