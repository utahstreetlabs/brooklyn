require 'brooklyn/sprayer'
require 'ladon'

module Users
  class ConnectionDigestEmailJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :connection_digest_email

    class << self
      def work(id)
        with_error_handling("sending connection digest email", user_id: id) do
          user = User.find(id)
          if user.allow_email?(:connection_digest)
            top_feed_listings = user.top_feed_listings(limit: self.max_listing_count)
            if top_feed_listings.count >= self.min_listing_count
              UserMailer.connection_digest(user, top_feed_listings).deliver
            else
              logger.warn "not enough listings to send connection digest email for user #{user.id}: got #{top_feed_listings.count}, needed #{min_listing_count}"
            end
          end
        end
      end

      def max_listing_count
        Brooklyn::Application.config.users.connection_digest.max_listing_count
      end

      def min_listing_count
        Brooklyn::Application.config.users.connection_digest.min_listing_count
      end
    end
  end
end
