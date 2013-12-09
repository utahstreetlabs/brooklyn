require 'anchor'
require 'flying_dog/resources/base'
require 'lagunitas'
require 'pyramid/resources/base'
require 'redhook'
require 'rising_tide'
require 'rubicon'

config = Brooklyn::Application.config

Ladon.hydra = Typhoeus::Hydra.new
Ladon.default_request_timeout = config.services.timeout

Anchor::Resource::Base.base_url = "http://#{config.anchor.host}:#{config.anchor.port}"
FlyingDog::ResourceBase.base_url = "http://#{config.flyingdog.host}:#{config.flyingdog.port}"
Lagunitas::Resource::Base.base_url = "http://#{config.lagunitas.host}:#{config.lagunitas.port}"
Pyramid::ResourceBase.base_url = "http://#{config.pyramid.host}:#{Brooklyn::Application.config.pyramid.port}"
Redhook::Resource::Base.base_url = "http://#{config.redhook.host}:#{config.redhook.port}"
Rubicon::Resource::Base.base_url = "http://#{config.rubicon.host}:#{config.rubicon.port}"

Rails.logger.info("Using Anchor service at #{Anchor::Resource::Base.base_url}")
Rails.logger.info("Using FlyingDog service at #{FlyingDog::ResourceBase.base_url}")
Rails.logger.info("Using Lagunitas service at #{Lagunitas::Resource::Base.base_url}")
Rails.logger.info("Using Pyramid service at #{Pyramid::ResourceBase.base_url}")
Rails.logger.info("Using Redhook service at #{Redhook::Resource::Base.base_url}")
Rails.logger.info("Using Rising Tide Redis at #{RisingTide::RedisModel.config} with env #{RisingTide::RedisModel.environment}")
Rails.logger.info("Using Rubicon service at #{Rubicon::Resource::Base.base_url}")
