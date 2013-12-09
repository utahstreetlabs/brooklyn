module CollectionFollows
  class AfterCreatedJob < Ladon::Job
    include Brooklyn::Sprayer
    include Stats::Trackable

    @queue = :collections

    def self.work(id)
      with_error_handling("After collection follow created", collection_follow_id: id) do
        collection_follow = CollectionFollow.find(id)
        inject_collection_follow_notification(collection_follow.collection, collection_follow.user)
        send_collection_follow_email(collection_follow.collection, collection_follow.user)
        update_mixpanel(collection_follow.collection, collection_follow.user)
      end
    end

    def self.inject_collection_follow_notification(collection, follower)
      unless collection.owned_by?(follower)
        inject_notification(:CollectionFollow, collection.user_id, collection_id: collection.id,
                            follower_id: follower.id)
      end
    end

    def self.send_collection_follow_email(collection, follower)
      unless collection.owned_by?(follower)
        send_email(:collection_follow, collection, follower.id) if collection.owner.allow_email?(:collection_follow)
      end
    end

    def self.update_mixpanel(collection, follower)
      unless collection.owned_by?(follower)
        track_usage(Events::FollowCollection.new(collection, follower))
      end
    end
  end
end
