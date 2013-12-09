require 'ladon'

class Users::SyncPhotoJob < Ladon::Job
  @queue = :photos

  def self.work(user_id, network)
    with_error_handling("Sync profile photo from #{network} for user #{user_id}", user_id: user_id, network: network) do
      user = User.find(user_id)
      user.set_profile_photo_from_network(network)
      user.save!(validate: false)
    end
  end
end
