require 'brooklyn/sprayer'
require 'ladon'

module Credits
  class AfterTriggerCreatedJob < Ladon::Job
    include Brooklyn::Sprayer

    @queue = :credits

    def self.work(id)
      with_error_handling("After credit trigger created", credit_id: id) do
        credit = Credit.find(id)
        trigger = credit.trigger
        if trigger && trigger.is_a?(Lagunitas::InviterCreditTrigger)
          inviter = credit.user
          invitee = User.find(trigger.invitee_id)
          send_invitee_purchase_credit_email(credit, inviter, invitee)
        end
      end
    end

    def self.send_invitee_purchase_credit_email(credit, inviter, invitee)
      send_email(:invitee_purchase_credit, inviter, invitee.to_job_hash)
    end
  end
end
