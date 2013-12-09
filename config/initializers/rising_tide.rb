require 'rising_tide'


config = Brooklyn::Application.config.rising_tide

RisingTide::RedisModel.environment = Rails.env
RisingTide::Story.config = {host: config.stories.host, port: config.stories.port}
RisingTide::ShardConfig.config = {host: config.shard_config.host, port: config.shard_config.port}
RisingTide::ActiveUsers.config = {host: config.active_users.host, port: config.active_users.port}
RisingTide::CardFeed.config = config.card_feeds.marshal_dump.each_with_object({}) {|(k, v), m| m[k] = v.marshal_dump }

RisingTide::CardFeed.feed_build_service =
  if Rails.env.test? || Rails.env.integration?
    RisingTide::FeedBuild::TestService.new
  else
    RisingTide::FeedBuild::StormService.new(config.drpc.servers, config.drpc.timeout, config.drpc.retries)
  end
