require 'carrierwave'

CarrierWave.configure do |config|
  config.root = "#{Rails.root}/public"
  cache_dir = [Rails.root, 'tmp', 'uploads', 'cache', Rails.env]
  cache_dir << ENV['TEST_ENV_NUMBER'] if ENV['TEST_ENV_NUMBER'].present?
  config.cache_dir = ::File.join(cache_dir)
  if Brooklyn::Application.config.files.respond_to?(:local)
    config.storage = :file
    store_dir = [Rails.root, 'public', Brooklyn::Application.config.files.local.dir]
    store_dir << ENV['TEST_ENV_NUMBER'] if ENV['TEST_ENV_NUMBER'].present?
    config.store_dir(::File.join(store_dir))
    Rails.logger.info("Storing files in #{config.store_dir} with cache #{config.cache_dir}")
  else
    config.storage = :fog
    config.fog_credentials = {
      :provider => 'AWS',
      :aws_access_key_id => Brooklyn::Application.config.aws.access_key_id,
      :aws_secret_access_key => Brooklyn::Application.config.aws.secret_access_key,
      :region => Brooklyn::Application.config.aws.region,
    }
    config.fog_directory = Brooklyn::Application.config.files.s3.bucket
    config.fog_host = "//#{config.fog_directory}.s3.amazonaws.com"
    config.store_dir = nil
    Rails.logger.info("Storing files in s3://#{config.fog_directory} with cache #{config.cache_dir}")
  end
  if Rails.env.test? || Rails.env.integration?
    config.enable_processing = false
  end
end
