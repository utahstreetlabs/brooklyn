require 'resque'

module Profiles
  class SyncAll < SyncBase
    def self.rubicon_class
      Rubicon::Jobs::Sync
    end
  end
end
