require 'spec_helper'

describe Users::RecentListingsQueuePolicy do
  describe '.find_candidate_listing_ids' do
    it 'splits listed and saved evenly when both queues are full' do
      user = stub_user('Mitt Romney',
                       recent_listed_listing_ids: stub_recent_listed_listing_ids([123, 456, 789, 1234]),
                       recent_saved_listing_ids: stub_recent_saved_listing_ids([987, 654, 321, 109]))
      subject.find_candidate_listing_ids([user]).should == {user.id => [1234, 789, 109, 321]}
    end

    it 'fills in with saved when not enough listed' do
      user = stub_user('Mitt Romney',
                       recent_listed_listing_ids: stub_recent_listed_listing_ids([123]),
                       recent_saved_listing_ids: stub_recent_saved_listing_ids([987, 654, 321, 109]))
      subject.find_candidate_listing_ids([user]).should == {user.id => [123, 109, 321, 654]}
    end

    it 'fills in with loved when not enough saved and listed' do
      user = stub_user('Mitt Romney',
                       recent_listed_listing_ids: stub_recent_listed_listing_ids([123]),
                       recent_saved_listing_ids: stub_recent_saved_listing_ids([456]),
                       recent_listing_ids: stub_recent_loved_listing_ids([987, 654, 321, 109]))
      subject.find_candidate_listing_ids([user]).should == {user.id => [123, 456, 109, 321]}
    end

    it 'leaves slots empty when not enough loved' do
      user = stub_user('Mitt Romney',
                       recent_listed_listing_ids: stub_recent_listed_listing_ids([123]),
                       recent_saved_listing_ids: stub_recent_saved_listing_ids([456]),
                       recent_listing_ids: stub_recent_loved_listing_ids([987]))
      subject.find_candidate_listing_ids([user]).should == {user.id => [123, 456, 987]}
    end
  end

  def stub_recent_listed_listing_ids(ids)
    stub('listed', any?: ids.any?, values: ids)
  end

  def stub_recent_saved_listing_ids(ids)
    stub('saved', any?: ids.any?, values: ids)
  end

  def stub_recent_loved_listing_ids(ids)
    stub('loved', any?: ids.any?, values: ids)
  end
end
