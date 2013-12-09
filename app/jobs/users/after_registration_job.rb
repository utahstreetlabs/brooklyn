require 'brooklyn/sprayer'
require 'draft_listing_reminder'
require 'facebook/follow_registered_friends'
require 'grant_invitee_credit'
require 'ladon'
require 'welcome_two'
require 'welcome_three'
require 'welcome_four'
require 'welcome_five'

module Users
  class AfterRegistrationJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :users

    class << self
      def work(id, options = {})
        with_error_handling("After registration of user #{id} with options #{options}") do
          user = User.find(id)
          grant_invitee_credit(user)
          email_invite_accepted(user)
          # XXX: temporarily taking this out as per request by product
          #email_welcome_1(user, options)
          email_joined(user)
          # XXX: take this out for now by request from Jim
          #schedule_draft_listing_reminder(user)
          schedule_follows(user)
          update_mixpanel(user)
        end
      end

      def grant_invitee_credit(user)
        GrantInviteeCredit.enqueue(user.id) if user.accepted_invite?
      end

      def email_invite_accepted(user)
        user.inviters.each do |inviter|
          send_email(:invite_accepted, inviter, user.to_job_hash) if inviter and inviter.allow_email?(:invite_accept)
        end
      end

      def email_welcome_1(user, options = {})
        send_email(:welcome_1, user) if options[:send_welcome_emails]
      end

      def email_joined(user)
        user.all_registered_network_followers.each do |follower|
          if not user.inviters.include?(follower) and follower.allow_email?(:friend_join)
            send_email(:friend_joined, user, follower.id)
          end
        end
      end

      def schedule_draft_listing_reminder(user)
        DraftListingReminder.enqueue_at(1.day.from_now, user.id)
      end

      def schedule_follows(user)
        user.schedule_follows
      end

      def update_mixpanel(user)
        user.mixpanel_sync!
        user.inviters.each do |u|
          u.mark_inviter!
          u.mixpanel_sync!
        end
      end
    end
  end
end
