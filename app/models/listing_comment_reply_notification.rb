class ListingCommentReplyNotification < ListingNotification
  attr_accessor :replier

  def complete?
    super && !replier.nil?
  end
end
