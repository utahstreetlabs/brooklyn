require 'sync/listings/adapter'
require 'sync/listings/source'
require 'sync/listings/s3_fetchable'
require 'sync/listings/kyozou_provider'
require 'sync/listings/channel_advisor_provider'
require 'sync/listings/e_drop_off'
require 'sync/listings/ajm'

module Sync
  module Listings
    mattr_accessor :active_sources
  end
end
