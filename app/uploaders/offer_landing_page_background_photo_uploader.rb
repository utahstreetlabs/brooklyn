class OfferLandingPageBackgroundPhotoUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick

  SIZES = [[30, 30], [70, 70], [1400, 900]]

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
end
