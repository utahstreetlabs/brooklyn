# copied wholesale from spec/support/carrierwave.rb
RSpec.configure do |config|
  config.after(:suite) do
    # nuke the (environment-specific) upload cache
    FileUtils.rm_rf(Dir["#{CarrierWave::Uploader::Base.cache_dir}/[^.]*"])
    # if storing upload files locally, nuke everything in the (environment-specific) local store
    if Brooklyn::Application.config.files.respond_to?(:local) && CarrierWave::Uploader::Base.store_dir
      FileUtils.rm_rf(Dir["#{CarrierWave::Uploader::Base.store_dir}/[^.]*"])
    end
  end
end
