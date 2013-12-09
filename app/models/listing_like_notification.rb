class ListingLikeNotification < ListingNotification
  attr_accessor :liker

  def complete?
    super && !liker.nil?
  end
end
