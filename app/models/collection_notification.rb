class CollectionNotification < Notification
  attr_accessor :collection, :follower

  def complete?
    ! (collection.nil? || follower.nil?)
  end
end
