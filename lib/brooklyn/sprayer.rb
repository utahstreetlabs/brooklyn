require 'active_support/concern'
require 'lagunitas/models/notification'
require 'ladon'
require 'resque_scheduler'

module Brooklyn
  # A concern that extends an application component with the ability to "spray" events to various system services
  # such as the background job queue and the mail queue.
  module Sprayer
    extend ActiveSupport::Concern
    include Brooklyn::Instrumentation
    include Ladon::Logging
    include Stats::Trackable
    delegate :send_email, :inject_notification, :inject_story, :inject_listing_story,
      :grant_credit, to: 'self.class'

    module ClassMethods
      def send_email(message, model, *args)
        SendModelMail.enqueue(model.class.name, message.to_s, model.id, *args)
      end

      def inject_notification(type, user_id, attrs = {})
        fire_user_notification_event(:app, {type: type, user_id: user_id})
        Lagunitas::Notification.async_create(type, user_id, attrs)
      end

      # @param [Symbol] type the story type
      # @param [Integer] actor_id the id of the user performing the action that spawned the story
      # @param [Hash] attrs additional attributes for the story
      # @param [Hash] options
      # @option options [Symbol] :feed (all) the feed(s) that should receive the story
      # @see #Stories::Create#perform
      def inject_story(type, actor_id, *args)
      end

      # @param [Symbol] type the story type
      # @param [Integer] actor_id the id of the user performing the action that spawned the story
      # @param [Integer] listing the listing upon which the action was performed
      # @param [Hash] attrs additional attributes for the story
      # @param [Hash] options
      # @option options [Symbol] :feed (all) the feed(s) that should receive the story
      # @option options [Symbol] :with_tag_followers (true) whether or not interest in the story should be registered
      #   for followers of the listing's tags
      # @see #inject_story
      def inject_listing_story(type, actor_id, listing, *args)
      end

      def grant_credit(user, type, attrs = {})
        GrantCredit.enqueue(user.id, type, attrs)
      end

      def url_helpers
        Brooklyn::Application.routes.url_helpers
      end
    end
  end
end
