require 'ladon'

class RecreatePhotoVersions < Ladon::Job
  @queue = :photo_processing

  def self.work(clazz, photo_id, *versions)
    with_error_handling("processing #{clazz} versions", photo_id: photo_id) do
      clazz.to_s.constantize.find(photo_id).file.recreate_versions!(*versions.map(&:to_sym))
    end
  end
end
