require 'rubicon'

Rubicon.configure do |config|
  config.twitter_consumer_key = Network::Twitter.app_id
  config.twitter_consumer_secret = Network::Twitter.app_secret

  config.tumblr_consumer_key = Network::Tumblr.app_id
  config.tumblr_consumer_secret = Network::Tumblr.app_secret

  config.instagram_consumer_key = Network::Instagram.app_id
  config.instagram_consumer_secret = Network::Instagram.app_secret

  config.instagram_consumer_key_secure = Network::Instagram::Secure.app_id
  config.instagram_consumer_secret_secure = Network::Instagram::Secure.app_secret

  config.facebook_consumer_key = Network::Facebook.app_id
  config.facebook_consumer_secret = Network::Facebook.app_secret
  config.facebook_access_token = Network::Facebook.access_token

  config.follow_rank.facebook.shared_connections_coefficient =
    Network::Facebook.config.follow_rank.shared_connections.coefficient
  config.follow_rank.facebook.network_affinity_coefficient =
    Network::Facebook.config.follow_rank.network_affinity.coefficient
  config.follow_rank.facebook.photo_tags_minimum =
    Network::Facebook.config.follow_rank.photo_tags.minimum
  config.follow_rank.facebook.photo_tags_coefficient =
    Network::Facebook.config.follow_rank.photo_tags.coefficient
  config.follow_rank.facebook.photo_annotations_window =
    Network::Facebook.config.follow_rank.photo_annotations.window
  config.follow_rank.facebook.photo_annotations_coefficient =
    Network::Facebook.config.follow_rank.photo_annotations.coefficient
  config.follow_rank.facebook.status_annotations_window =
    Network::Facebook.config.follow_rank.status_annotations.window
  config.follow_rank.facebook.status_annotations_coefficient =
    Network::Facebook.config.follow_rank.status_annotations.coefficient

  config.flyingdog_enabled = true
end
