require 'active_support/concern'
require 'stats/trackable'

module People
  # Person API for sharing to external networks.
  module Shareable
    extend ActiveSupport::Concern
    include Stats::Trackable

    module InstanceMethods
      # Shares a +listing_activated+ event to the external network. Assumes the sharer is the listing's
      # seller.
      def share_listing_activated(network, listing, listing_url)
        share_listing_event(:listing_activated, network, listing, listing_url)
      end

      # Shares a +listing_liked+ event to the external network. Assumes the sharer is the liker.
      def share_listing_liked(network, listing, listing_url, options={})
        unless options[:shared].present? and options[:shared].to_sym == network.to_sym
          share_listing_event(:listing_liked, network, listing, listing_url, {},
            other_user_profile: listing.seller.person.for_network(network))
        end
      end

      # Shares a +listing_commented+ event to the external network. Assumes the sharer is the commenter.
      def share_listing_commented(network, listing, listing_url, comment_text)
        share_listing_event(:listing_commented, network, listing, listing_url, {comment: comment_text},
          other_user_profile: listing.seller.person.for_network(network))
      end

      # Shares a +user_followed+ event to the external network. Assumes the sharer is the follower.
      def share_user_followed(network, followee, followee_url)
        share_user_event(:user_followed, network, followee, followee_url, {},
          other_user_profile: followee.person.for_network(network))
      end

      # Shares a listing event to the external network.
      def share_listing_event(event, network, listing, listing_url, params = {}, options = {})
        profile = for_network(network)
        raise ArgumentError.new("No #{network} profile for person #{self.id}") unless profile
        params = {firstname: profile.first_name, listing: listing.title, listing_id: listing.id, link: listing_url}.
          merge(params)
        params[:other_user_username] = options[:other_user_profile].username if options[:other_user_profile]
        params[:picture] = "http:#{listing.photos.first.version_url(:small)}" if
          Listing.photos_stored_remotely? and listing.photos.first
        share_event(event, profile, params, options)
      end

      # Shares a user event to the external network.
      def share_user_event(event, network, user, user_url, params = {}, options = {})
        profile = for_network(network)
        raise ArgumentError.new("No #{network} profile for person #{self.id}") unless profile
        params = {firstname: profile.first_name, other_user: user.name, other_user_id: user.id, link: user_url}.
          merge(params)
        params[:other_user_username] = options[:other_user_profile].username if options[:other_user_profile]
        params[:picture] = "http:#{user.profile_photo.url(:px_70x70)}" if
          User.photos_stored_remotely? and user.profile_photo
        share_event(event, profile, params, options)
      end

      # Creates a post in the external network.
      def share_event(event, profile, params = {}, options = {})
        options = self.class.sharing_options!(event, profile.network, params, options)
        logger.debug("Sharing #{event} to #{profile.network} for person #{self.id} with options #{options}")
        rv = profile.post_to_feed(options)
        track_usage("share_#{profile.network}_#{event}", params.merge(user: self.user))
        rv
      end
    end

    module ClassMethods
      # Calls network-specific method to update params for rendering a post shared to
      # an external network.  Destructive: can update params in-place.
      # @param [Symbol] event action triggering the share
      # @param [Symbol] network network being shared to
      # @param [Hash] params parameters filled into template to render shared text
      # @param [Hash] options options that control how the shared message is rendered
      def sharing_options!(event, network, params, options = {})
        Network.klass(network).message_options!("share_#{event}".to_sym, params, options)
      end
    end
  end
end
