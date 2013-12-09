require 'redis'
require 'redis/objects'
require 'resque'
require 'resque_scheduler'
require 'resque-retry'
require 'resque/failure/redis'

def setup_redis_connections
  config = Brooklyn::Application.config.redis
  User.redis = Redis.new(host: config.cache.host, port: config.cache.port)
  ListingListSnapshot.redis = Redis.new(host: config.cache.host, port: config.cache.port)
  Resque.redis = Redis.new(host: config.resque.host, port: config.resque.port)
end

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      # We're in smart spawning mode. If we're not, we do not need to do anything
      setup_redis_connections
    end
  end
else
  setup_redis_connections unless Rails.env.test?
end

unless Rails.env.test?
  Resque.schedule = YAML.load_file("#{Rails.root}/config/resque_schedule.yml")

  # don't insert failures into the failure queue if they are just waiting to be retried
  Resque::Failure::MultipleWithRetrySuppression.classes = [Resque::Failure::Redis]
  Resque::Failure.backend = Resque::Failure::MultipleWithRetrySuppression

  Rails.logger.info("Caching user data in Redis at #{User.redis.client.host}:#{User.redis.client.port}")
  Rails.logger.info("Persisting resque queues in Redis at #{Resque.redis.client.host}:#{Resque.redis.client.port}")
end
