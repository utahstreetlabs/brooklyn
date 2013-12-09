class CollectionFollow < ActiveRecord::Base
  include Stats::Trackable
  belongs_to :user
  belongs_to :collection, counter_cache: :follower_count
  attr_accessible :collection

  after_commit on: :create do
    CollectionFollows::AfterCreatedJob.enqueue(self.id)
  end

  after_commit on: :destroy do
    track_usage(Events::UnfollowCollection.new(collection, user))
  end

  def self.counts_for_collections(collection_ids)
    CollectionFollow.where(collection_id: collection_ids).count(group: :collection_id)
  end
end
