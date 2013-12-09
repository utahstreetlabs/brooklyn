require 'brooklyn/sprayer'
require 'ladon'
require 'lagunitas/models/credit_triggers/inviter_credit_trigger'
require 'send_credit_reminder_one'
require 'send_credit_reminder_two'

module Credits
  class AfterCreatedJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :credits

    def self.work(id)
      with_error_handling("After credit created", credit_id: id) do
        credit = Credit.find(id)
        send_inviter_credit_granted_email(credit)
        inject_credit_granted_notification(credit)
        schedule_credit_reminder_1(credit)
        schedule_credit_reminder_2(credit)
        update_mixpanel(credit)
      end
    end

    def self.send_inviter_credit_granted_email(credit)
      if credit.trigger && credit.trigger.is_a?(Lagunitas::InviterCreditTrigger)
        invitee = User.find_by_id(credit.trigger.invitee_id)
        user = User.find_by_id(credit.user_id)
        if invitee && user
          send_email(:invitee_purchase_credit, user, invitee.to_job_hash)
        end
      end
    end

    def self.inject_credit_granted_notification(credit)
      inject_notification(:CreditGranted, credit.user_id, credit_id: credit.id)
    end

    def self.schedule_credit_reminder_1(credit)
      days_duration = Time.zone.at(credit.validity_duration).day
      if days_duration >= Credit.min_days_halfway_reminder
        SendCreditReminderOne.enqueue_at((days_duration / 2).day.from_now, credit.id)
      end
    end

    def self.schedule_credit_reminder_2(credit)
      SendCreditReminderTwo.enqueue_at(credit.expires_at.yesterday, credit.id)
    end

    def self.update_mixpanel(credit)
      credit.user.mixpanel_increment!(credits_earned: credit.amount)
    end
  end
end
