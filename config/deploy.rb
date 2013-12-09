require 'bundler/capistrano'
require 'hipchat/capistrano'
require 'airbrake/capistrano'
require './config/boot'

set :stages, %w(demo development staging production)
set :default_stage, "staging"
require 'capistrano/ext/multistage'

set :user, 'utah'
set :application, 'brooklyn'
set :app_port, 8080
# domain is set in config/deploy/{stage}.rb

# file paths
set :repository, "git@github.com:utahstreetlabs/brooklyn.git"
set(:deploy_to) { "/home/#{user}/#{application}" }

# set asset prefix
_cset :assets_prefix, "assets"

##
## BEHAVIORAL FLAGS
##
## Set these to true or false to signal if you want the build to execute these behaviors.
##

# Set this to true if you want to reindex Solr
set :reindex_solr, false

# Set this to true if you want to run database migrations
set :migrate_db, true

# Set this to a seed file filter string if you want to load database seed data from one or more files.
# example: '005' will load all files in db/fixtures/ whose names contain the string '005'
# IMPORTANT: feature_flags should always be in the filter string in order for feature flags to be seeded as they are
# added
set :db_seed_filter, 'flags'

# Set this to true if you want to minify js and css
set :minify, true

##
## END BEHAVIORAL FLAGS
##

# one server plays all roles
role :app do
  fetch(:app_hosts)
end
role :proxy do
  fetch(:proxy_hosts)
end
role :web do
  fetch(:app_hosts)
end
role :db, :primary => true do
  fetch(:app_hosts)
end
# there should only ever be one scheduler per resque instance
# otherwise double jobs will be scheduled
role :scheduler do
  fetch(:scheduler_host)
end

role :db_migrate do
  fetch(:db_migrate_host)
end

role :worker do
  fetch(:worker_hosts)
end

set(:rails_env) { stage }
set :deploy_via, :remote_cache
set :scm, 'git'
set :scm_verbose, true
set(:branch) do
  case stage
  when :production then "production"
  else "staging"
  end
end
set :use_sudo, false

set :hipchat_token, ''
set :hipchat_room_name, 'bots'
set :hipchat_announce, true

before "deploy:update", "deploy:setup"
after "deploy", "deploy:cleanup"

namespace :deploy do
  desc 'Restart Resque task scheduler'
  task :restart_scheduler, :roles => :scheduler do
    run "#{sudo} stop resque-scheduler ; true"
    #hammerfist killing of scheduler to work around kernel bug in 2.6.28
    #lets allow for the upstart to send its kill after 5 seconds, then smash
    run "sleep 6 ; ps -ef | grep resque-scheduler | grep -v grep | awk '{print $2}' | xargs -r kill -9"
    run "#{sudo} start resque-scheduler"
  end
  before "deploy:restart", "deploy:restart_scheduler"

  desc 'Restart Resque worker pool'
  task :restart_pool, :roles => :worker do
    #gracefully restart so we don't kill current long running job
    run "kill -QUIT `ps -ef | grep resque-pool-master | grep -v grep |awk '{print $2}'`"
  end
  before "deploy:restart", "deploy:restart_pool"

  desc 'NOOP deploy:symlink'
  task :symlink, :roles => :app do
  end

  task :symlink, :roles => [:worker, :scheduler] do
      run "rm -f #{current_path} && ln -s #{latest_release} #{current_path}"
  end

  namespace :assets do
    desc <<-DESC
      [internal] This task will set up a symlink to the shared directory \
      for the assets directory. Assets are shared across deploys to avoid \
      mid-deploy mismatches between old application html asking for assets \
      and getting a 404 file not found error. The assets cache is shared \
      for efficiency. If you cutomize the assets path prefix, override the \
      :assets_prefix variable to match.

      Copied directly from Capistrano: we need to symlink to keep old assets
      on the path and ensure the manifest is available, but don't want to
      precompile assets on the host.
    DESC
    task :symlink, :roles => [:web, :worker], :except => { :no_release => true } do
      run <<-CMD
        rm -rf #{latest_release}/public/#{assets_prefix} &&
        mkdir -p #{latest_release}/public &&
        mkdir -p #{shared_path}/assets &&
        ln -s #{shared_path}/assets #{latest_release}/public/#{assets_prefix}
      CMD
    end
    before 'deploy:finalize_update', 'deploy:assets:symlink'

    task :copy_manifest, :roles => [:web, :worker] do
      top.upload("public/assets/manifest.yml", "#{shared_path}/assets/manifest.yml")
    end
    before "deploy:assets:symlink", "deploy:assets:copy_manifest"
  end

  desc 'Restart Passenger'
  task :restart, :roles => :app  do
    # Restart each passenger host serially
    run "mkdir -p #{latest_release}/tmp"
    #Get all of the app/web services
    find_servers_for_task(current_task).each do |app_server|
      #Get all of the proxy services
      proxy_servers = find_servers :roles => :proxy
      proxy_servers.each do |server|
        ENV['HOSTFILTER'] = server.host
        run "/home/utah/bin/del_web_from_proxy.sh #{app_server.host}"
        ENV['HOSTFILTER'] = nil
      end
      run "rm -f #{current_path} && ln -s #{latest_release} #{current_path}", :hosts => app_server.host
      run "sudo /etc/init.d/apache2 restart", :hosts => app_server.host
      # before putting the host back in rotation, run the smoke test to ensure that the app is fully functional
      # exit code on error is 1, which should make the run command fail and roll back the release
      run "cd #{current_path} && bin/thor brooklyn:smoke --host #{app_server.host} --port #{app_port} --timeout 360000", :hosts => app_server.host
      proxy_servers.each do |server|
        ENV['HOSTFILTER'] = server.host
        # if we made it this far, the host is safe to be put back into rotation
        run "/home/utah/bin/add_web_to_proxy.sh #{app_server.host}"
        ENV['HOSTFILTER'] = nil
      end
    end
  end

  desc 'Reindex Solr'
  task :reindex, :roles => :db_migrate do
    run "cd #{latest_release} && RAILS_ENV=#{stage} bin/rake sunspot:reindex" if reindex_solr
  end
  after "deploy:seed", "deploy:reindex"

  desc 'Migrate database'
  task :migrate, :roles => :db_migrate do
    run "cd #{latest_release}&& RAILS_ENV=#{stage} bin/rake db:migrate" if migrate_db
  end
  after "deploy:restart", "deploy:migrate"

  desc 'Seed database'
  task :seed, :roles => :scheduler do
    run "cd #{latest_release} && RAILS_ENV=#{stage} bin/rake db:seed_fu FILTER='#{db_seed_filter}'" if db_seed_filter
  end
  after "deploy:migrate", "deploy:seed"
end
