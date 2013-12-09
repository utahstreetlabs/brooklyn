class SecretSellerItemPhotoUploader < CarrierWave::Uploader::Base
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def store_dir
    path = "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    self.class.store_dir.present?? "#{self.class.store_dir}/#{path}" : path
  end
end
