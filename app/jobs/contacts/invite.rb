require 'rpx_now'
require 'ladon'

module Contacts
  # this job actually just performs a 'fanout' in order to take advantage of the existing async mail infrastructure
  # and allow jobs to be retried individually, but without requiring the controller to synchronously inject what
  # could be hundreds of resque jobs
  class Invite < Ladon::Job
    @queue = :contacts

    def self.work(user_id, contact_ids)
      Contact.find_by_ids_with_email_accounts(contact_ids).each do |contact|
        contact.invite
      end
    end
  end
end
