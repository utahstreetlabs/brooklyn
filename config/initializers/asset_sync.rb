AssetSync.configure do |config|
  config.fog_provider = 'AWS'
  config.aws_access_key_id = Brooklyn::Application.config.aws.access_key_id
  config.aws_secret_access_key = Brooklyn::Application.config.aws.secret_access_key
  config.fog_directory = Brooklyn::Application.config.assets.bucket

  # Increase upload performance by configuring your region
  # config.fog_region = 'eu-west-1'
  #
  # Don't delete files from the store
  config.existing_remote_files = "keep"
  #
  # Automatically replace files with their equivalent gzip compressed version
  config.gzip_compression = true
  #
  # Update these files, even if they already exist.
  # In the case of sdk.js, we want to make sure it's current, because we are going to access it without
  # the appended hash so that we can give out a consistent URL to anyone embedding it.
  config.always_upload = ['sdk.js', 'bookmarklet.js']
  #
  # Use the Rails generated 'manifest.yml' file to produce the list of files to
  # upload instead of searching the assets directory.
  # config.manifest = true
  #
  # Fail silently.  Useful for environments such as Heroku
  # config.fail_silently = false
end if defined?(AssetSync)
