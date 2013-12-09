class ListingCommentNotification < ListingNotification
  attr_accessor :commenter

  def complete?
    super && !commenter.nil?
  end
end
