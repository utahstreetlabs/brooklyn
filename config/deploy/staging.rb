set :app_hosts, ['staging3.copious.com','staging4.copious.com','staging5.copious.com']
set :proxy_hosts, ['staging3.copious.com','staging4.copious.com']
set :scheduler_host, 'staging4.copious.com'
set :worker_hosts, ['staging3.copious.com', 'staging4.copious.com']
set :db_migrate_host, 'staging4.copious.com'
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

# Load RVM's capistrano plugin.    
require "rvm/capistrano"

set :rvm_ruby_string, '1.9.3-p0'
set :rvm_type, :user
