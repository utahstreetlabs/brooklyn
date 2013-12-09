require 'rpx_now'
require 'ladon'

module Contacts
  class Import < Ladon::Job
    include Stats::Trackable

    @queue = :contacts

    def self.work(email_account_id)
      account = EmailAccount.find(email_account_id)
      account.sync_contacts!
      track_usage(:address_book_import, user: account.user)
    end
  end
end
