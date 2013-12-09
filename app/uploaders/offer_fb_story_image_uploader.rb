class OfferFbStoryImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick

  MIN_HEIGHT = 50
  MIN_WIDTH = 50
  MAX_ASPECT_RATIO = 3
  MAX_ASPECT_RATIO_STR = '3:1'

  SIZES = [[70, 70]]
  # the original is used for the FB story, and the 70x70 is used as a thumbnail for the admin UI

  SIZES.each do |width, height|
    version :"px_#{width}x#{height}" do
      process resize_to_fill: [width, height]
    end
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def store_dir
    path = "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    self.class.store_dir.present?? "#{self.class.store_dir}/#{path}" : path
  end

  def geometry
    if @file && !@geometry
      img = ::Magick::Image.from_blob(@file.read).first
      @geometry = Hashie::Mash.new(height: img.rows, width: img.columns)
    end
    @geometry
  end

  def aspect_ratio
    geometry.width.to_f / geometry.height.to_f
  end

  def valid_size?
    geometry.height >= MIN_HEIGHT && geometry.width >= MIN_WIDTH
  end

  def valid_aspect_ratio?
    aspect_ratio <= MAX_ASPECT_RATIO
  end
end
