require 'resque/tasks'
require 'resque_scheduler/tasks'
require 'resque/pool/tasks'

task "resque:setup" => :environment do
  # make sure puts are flushed automatically - logs were not flushing
  # when rake tasks were run as upstart jobs in staging
  # we should turn this on if we'd like to insert jobs dynamically
  # Resque::Scheduler.dynamic = true
end

task "resque:pool:setup" do
  # close any sockets or files in pool manager
  ActiveRecord::Base.connection.disconnect!
  Vanity.playground.disconnect!
  # and re-open them in the resque worker parent
  Resque::Pool.after_prefork do |job|
    ActiveRecord::Base.establish_connection
    Vanity.playground.establish_connection
  end
end
