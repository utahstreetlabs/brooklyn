require 'ladon'

module Network
  class SyncStaleProfilesJob < Ladon::Job
    @queue = :network_slow

    def self.work(seconds = nil)
      num_synced = 0
      with_error_handling("Sync network profiles for users not synced in the last #{seconds} seconds") do
        User.each_unsynced_after_deleting_inactive(seconds) do |user|
          # Touch last synced here so that if we get an exception (such as due to password change)
          # we still consider the profile synced, so we don't try over and over
          user.touch_last_synced
          num_synced += 1
          user.person.connected_networks.each do |network|
            # Ignore facebook for now. The purpose of this job was to keep twitter follower counts up-to-date.
            # This isn't retrievable in sync attrs in the case of fb anyway, but these sync attrs jobs
            # are accounting for a lot of the jobs in the failed queue for invalid tokens.
            unless network == :facebook
              Array(user.person.for_network(network)).each do |profile|
                if profile.connected?
                  with_error_handling("Sync stale #{network} profile #{profile.uid} for user #{user.id}") do
                    begin
                      profile.async_sync_attrs
                    rescue NotImplementedError
                      # XXX: Rubicon::Profile needs to either get rid of the base class implementation of sync_attrs
                      # or provide can_sync_attrs? so we know not to bother syncing a Facebook page
                    end
                  end
                end
              end
            end
          end
        end
      end
      num_synced
    end
  end
end
