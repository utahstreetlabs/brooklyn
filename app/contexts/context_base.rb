require 'brooklyn/instrumentation'
require 'brooklyn/sprayer'
require 'brooklyn/urls'
require 'stats/trackable'

class ContextBase
  include Brooklyn::Instrumentation
  include Brooklyn::Sprayer
  include Brooklyn::Urls
  include Stats::Trackable
end
