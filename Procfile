# these commands are only appropriate for development
brooklyn: bundle exec rails server thin
worker: bundle exec resque-pool --environment development
scheduler: bin/resque-scheduler
# http://127.0.0.1:1080
mailcatcher: bundle exec mailcatcher -f
