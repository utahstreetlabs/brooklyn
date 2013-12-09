require 'yaml'
require 'resque' # include resque so we can configure it
# Resque.redis = "redis_server:6379" # tell Resque where redis lives

# This will make the tabs show up.
require 'resque_scheduler'

RAILS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

Resque.schedule = YAML.load_file(RAILS_ROOT + '/config/resque_schedule.yml') # load the schedule

PATHS = ['app/contexts', 'app/exhibits', 'app/hooks', 'app/jobs', 'app/searchers', 'app/presenters', 'lib',
         'app/controller_observers', 'app/messages']
PATHS.each do |dir|
  $: << File.expand_path(File.join(RAILS_ROOT, dir))
end

# load all the jobs so they'll be resolvable in the schedule tab
JOBS_PATHS = ['app/jobs', 'app/jobs/facebook']
JOBS_PATHS.each do |dir|
  jobs_dir = File.join(RAILS_ROOT, dir)
  Dir[jobs_dir + '/*.rb'].each do |file|
    require File.join(JOBS_DIR, File.basename(file, File.extname(file)))
  end
end
