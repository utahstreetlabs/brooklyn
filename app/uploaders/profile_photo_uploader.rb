# This uploader creates profile photos for users.  It is expected that they will eventually come from multiple
# locations, but for now it just seeds their profile photo by pulling it from facebook.  The class plays multiple
# roles, including:
#
# Initial seeding:
#   This task is performed using CarrierWave's `download!` method.  However, Facebook's profile photos are stored
#   in a CDN, to which the request is redirected.  We don't want to pull down thousands of copies of their default
#   profile image, so if we check the url pattern of the redirect and ignore if it's taking us to the default.
#   Also helpful because rmagick thinks their default image is corrupt.
#
#   The above logic is in `download_from_facebook!`, leveraging the recursive method `actual_url`, which follows
#   redirects (just using HEAD) and returns `nil` if it doesn't find anything useful.
#
# Default image:
#   In the case that no image has been set for a user, we return a default image.  This work is done by the
#   `url` method, which is an override of that found in CarrierWave::Uploader::Url.  There is a concept of
#   `default_url` in CarrierWave::Uploader::DefaultUrl, but it doesn't play nicely with versions.
#
# Multiple Versions:
#   CarrierWave supports generating multiple versions of a file by looking for any registered versions.  We want a
#   few, and the dimensions are stored in `@@sizes`.  For each WxH pair, we request a version and give it a name
#   of the form 'px_WxH'.  Then, in the `download!` method, CarrierWave will cache the original and write each of
#   these versions into the 'store' (either filesystem or s3).
#
#   When a request is made for this photo (something like `user.profile_photo`) it can accept a version as an
#   argument (e.g. `user.profile_photo(:px_50x50)`) and will a url to that version of the file.

require 'carrierwave'
require 'typhoeus'
require 'brooklyn/urls'

class ProfilePhotoUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick
  include Brooklyn::Urls

  cattr_accessor :default_file_name
  @@default_file_name = Brooklyn::Application.config.profile_photo.default_name

  cattr_accessor :default_file_path
  @@default_file_path = Brooklyn::Application.config.profile_photo.default_path

  cattr_accessor :fb_ignore_pattern
  @@fb_ignore_pattern = /static-ak/

  cattr_accessor :sizes
  @@sizes = [[30, 30], [50, 50], [70, 70], [150, 150], [190, 190]]

  @@sizes.each do |width, height|
    version :"px_#{width}x#{height}" do
      process :resize_to_fill => [width, height]
    end
  end

  cattr_accessor :skip_photo_extension_check
  @@skip_photo_extension_check = false

  def url(*args)
    # if this method is called with args, it's to get a specific version
    if args.first
      # if file is not set at this point, we'll get the default
      @file ||= retrieve_from_store!(@@default_file_name)
      super(*args)
    else
      # at this point, file is set, even if it's the default, so that's why we (hopefully) picked a crazy filename
      # it will have the version prepended, so we're just checking the ending

      # also, if it's a local file, we can get the filename directly, but if's in AWS we have to split the url
      # and take the last part
      filename = if file.respond_to?(:identifier)
        file.identifier
      else
        url = super
        url.split('/')[-1] if url
      end

      if filename.present? && filename.end_with?(@@default_file_name)
        absolute_url("#{@@default_file_path}/#{filename}", root_url: Brooklyn::Application.config.action_controller.asset_host)
      else
        super
      end
    end
  end

  def extension_white_list
    skip_photo_extension_check ? nil : %w(jpg jpeg gif png)
  end

  def store_dir
    path = "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    self.class.store_dir.present?? "#{self.class.store_dir}/#{path}" : path
  end

  # follow redirects to the final image (only getting HEAD data)
  # ignore if this is the default no-image image from facebook
  def actual_url(url, options = {})
    response = Typhoeus::Request.head(url)
    if response.success?
      url
    elsif response.code == 302 || response.code == 301
      location = response.headers_hash[:location]
      (location =~ fb_ignore_pattern) ? nil : actual_url(location)
    elsif response.timed_out?
      Rails.logger.error("time out fetching profile photo from [#{url}]")
      nil
    elsif response.code == 0
      Rails.logger.error(response.curl_error_message)
      nil
    elsif ((response.code == 403) || (response.code == 404)) && (options[:network] == :twitter)
      # Original size images for twitter may not exist
      Rails.logger.debug("Could not find image for twitter, url = #{url}")
      nil
    else
      Rails.logger.error("HTTP request failed: " + response.code.to_s)
      nil
    end
  end

  def download_from_network!(network)
    network = network.to_sym
    profile = model.person.for_network(network)
    skip_photo_extension_check = false
    url = case network
          when :facebook
            # use the actual_url method to skip default images
            actual_url(profile.typed_photo_url(:large))
          when :twitter
            # We want to temporarily override the extension white list, because twitter photos
            # can be hosted without an extension at the end of the url
            skip_photo_extension_check = true
            url = actual_url(Twitter.profile_image(profile.username, size: :original), network: network)
            url ||= actual_url(Twitter.profile_image(profile.username, size: :bigger), network: network)
          end
    download!(url) unless url.nil?
  end
end
