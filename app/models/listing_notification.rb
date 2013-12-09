class ListingNotification < Notification
  attr_accessor :listing, :seller, :commenter, :replier, :collection, :saver

  def complete?
    ! (listing.nil? || seller.nil?)
  end

  def self.factory(n)
    if n.respond_to?(:reply_id)
      ListingCommentReplyNotification.new(n)
    elsif n.respond_to(:comment_id)
      ListingCommentNotification.new(n)
    elsif n.respond_to?(:liker_id)
      ListingLikeNotification.new(n)
    elsif n.respond_to?(:saver_id)
      ListingSaveNotification.new(n)
    else
      new(n)
    end
  end
end
