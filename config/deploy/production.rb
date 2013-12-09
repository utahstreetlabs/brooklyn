set :app_hosts, {bot: (1..2), web: (3..8)}.flat_map {|type,ids| ids.map {|id| "#{type}#{id}.copious.com"}}
set :proxy_hosts, ['web3.copious.com','web8.copious.com']
set :scheduler_host, 'services2.copious.com'
set :worker_hosts, ['worker1.copious.com','worker2.copious.com']
set :db_migrate_host, 'services1.copious.com'
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

# Load RVM's capistrano plugin.    
require "rvm/capistrano"

set :rvm_ruby_string, '1.9.3-p0'
set :rvm_type, :user
