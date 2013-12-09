# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

Brooklyn::Application.load_tasks

if Rails.env.test? || Rails.env.development? || Rails.env.integration?
  desc "Run all non-selenium acceptance specs in acceptance directory"
  RSpec::Core::RakeTask.new(:'spec:acceptance:nojs' => :'db:test:prepare_with_data') do |t|
    t.pattern = "./acceptance/**/*_spec.rb"
    t.rspec_opts = "--tag ~js"
  end

  desc "Run all selenium acceptance specs in acceptance directory"
  RSpec::Core::RakeTask.new(:'spec:acceptance:js' => :'db:test:prepare_with_data') do |t|
    t.pattern = "./acceptance/**/*_spec.rb"
    t.rspec_opts = "--tag js"
  end

  desc "Run all non-flakey acceptance specs in acceptance directory"
  RSpec::Core::RakeTask.new(:'spec:acceptance:notflakey' => :'db:test:prepare_with_data') do |t|
    t.pattern = "./acceptance/**/*_spec.rb"
    t.rspec_opts = "--tag ~fails_in_jenkins --tag ~flakey"
  end

  desc "Run all flakey acceptance specs in acceptance directory"
  RSpec::Core::RakeTask.new(:'spec:acceptance:flakey' => :'db:test:prepare_with_data') do |t|
    t.pattern = "./acceptance/**/*_spec.rb"
    t.rspec_opts = "--tag ~fails_in_jenkins --tag flakey"
  end

  desc "Run all acceptance specs"
  task :'spec:acceptance' => [:'spec:acceptance:nojs', :'spec:acceptance:js']

  desc "Run all specs"
  task :'spec:all' => [:spec, :'spec:javascripts', :'spec:acceptance']

  desc "Run javascript specs"
  task :'spec:javascripts' => :'jasmine:ci'

  require 'parallel_tests/tasks'
  namespace :parallel do
    desc "load seed data via db:seed_fu --> parallel:seed_fu[num_cpus]"
    task :seed_fu, :count do |t, args|
      run_in_parallel("rake db:seed_fu RAILS_ENV=test FILTER=feature_flags", args)
    end

    task :prepare_with_data => [:prepare, :seed_fu]
  end
end

namespace :db do
  task :setup => :seed_fu

  namespace :test do
    desc "load seed data via db_seed_fu --> test db"
    task :seed_fu do
      system("rake db:seed_fu RAILS_ENV=test FILTER=feature_flags")
    end

    task :prepare_with_data => [:prepare, :seed_fu]
  end
end
