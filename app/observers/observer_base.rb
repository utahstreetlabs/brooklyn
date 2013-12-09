require 'brooklyn/instrumentation'
require 'brooklyn/sprayer'
require 'stats/trackable'

class ObserverBase < ActiveRecord::Observer
  include Brooklyn::Instrumentation
  include Brooklyn::Observer
  include Brooklyn::Sprayer
  include Stats::Trackable
end
