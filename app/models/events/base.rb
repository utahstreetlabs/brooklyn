module Events

  # A base class for domain events we'd like to track in a tool like Mixpanel.
  #
  # This base class encapsulates:
  #
  # 1) An event name suitable for use in an external tracking system like Mixpanel.
  #
  # 2) A set of preliminary event properties. These properties should be set in the
  #    subclass constructor and should be trivial to compute - "slow" operations like
  #    non-trivial database queries should be avoided.
  #
  # 3) Lazy loading of some event properties. Subclasses should implement a
  #    #complete_properties class method that takes a Hash of properties and
  #    performs additional computation/queries to return a superset Hash filled
  #    with additional data about the event. Helper methods for this computation
  #    are defined in this class.
  #
  #  It may be worth exploring passing a serialized version of instances of this
  #  class to backend jobs. I played with that for a few minutes before deciding it
  #  was more of an effort than I was interested in for now, but might make this
  #  code feel a bit cleaner.
  class Base
    attr_reader :properties
    class << self; attr_reader :event_name end

    def self.set_event_name(name)
      @event_name = name
    end

    # Load additional properties for this event. This may do expensive database
    # queries and take time, and should not be invoked in the context of an HTTP
    # request.
    #
    # @param
    def self.complete_properties(props)
      raise NotImplementedError
    end

    def self.listing_properties(listing_id)
      listing = Listing.find(listing_id)
      seller = listing.seller ? listing.seller.name : 'Guest'
      category = listing.category ? listing.category.name : 'None'
      size = listing.size ? listing.size.name : 'None'
      brand = listing.brand ? listing.brand.name : 'None'
      tags = listing.tags.map(&:name)
      handling_period = listing.handling_duration / 60 / 60 / 24 # stored as seconds, pass as days
      props = {
        created_at: listing.created_at,
        activated_at: listing.activated_at,
        seller_name: seller,
        listing_title: listing.title,
        category: category,
        condition: listing.condition,
        size: size,
        brand: brand,
        tags: tags,
        total_price: listing.total_price,
        price: listing.price,
        buyer_fee: listing.buyer_fee,
        seller_fee: listing.seller_fee,
        shipping_price: listing.shipping,
        handling_period: handling_period,
        platform: :web,
        state: listing.state,
        listing: listing.slug
      }
      props[:external_url] = listing.source.url if listing.respond_to?(:source) && listing.source
      props
    end

    def self.listing_social_properties(listing_id)
      listing = Listing.find(listing_id)
      {
        loves: listing.likes_count, comments: listing.comments_count, saves: listing.saves_count
      }
    end

    def self.order_properties(order_id)
      order = Order.find(order_id)
      {
        purchased_at: order.created_at, order_id: order_id, buyer_name: order.buyer.name,
        credits_used: order.credit_amount
      }
    end

    def self.profile_properties(user_id)
      user = User.find(user_id)
      {
        profile_name: user.slug, profile_listings_count: user.seller_listings.size,
        profile_follower_count: user.registered_followers.size,
        profile_following_count: user.registered_followees.size,
        profile_love_count: user.likes_count,
      }
    end

    def self.collection_properties(collection_id, options = {})
      if options[:viewer]
        viewer = options[:viewer]
      elsif options[:viewer_id]
        viewer = User.find(options[:viewer_id])
      end
      collection = options[:collection] ? options[:collection] : Collection.find(collection_id)
      props = {
        collection_name: collection.slug,
        collection_creator: collection.owner.slug,
        collection_items: collection.listing_count,
        collection_followers: collection.follower_count
      }
      if viewer
        props[:viewer_name] = viewer.slug
        props[:viewer_state] = 'logged_in'
        props[:viewer_type] = collection.owned_by?(viewer) ? 'owner' : 'visitor'
      else
        props[:viewer_state] = 'logged_out'
      end
      props
    end

    def self.followee_properties(user)
      {
        followee_collections: user.collections.count,
        followee_likes: user.likes_count,
        followee_listings: user.seller_listings.count,
        followee_following: user.followings.count,
        followee_followers: user.follows.count
      }
    end
  end
end
