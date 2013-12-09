class ListingFeed
  include Ladon::Logging

  attr_reader :listing, :users, :comments, :comments_by_id, :replies, :flaggers, :repliers

  def initialize(listing, values = nil)
    @listing = listing

    values ||= @listing.recent_comments(max: 25)

    # eager fetch and cache the associated users and filter the comments and replies that refer to nonexistent users
    user_ids = values.inject(Set.new) do |memo, comment|
      memo << comment.user_id
      memo.merge(comment.flags.map(&:user_id))
      memo.merge(comment.replies.map(&:user_id)) unless comment.is_a?(Anchor::CommentReply)
      memo
    end
    @users = User.where(id: user_ids.to_a).compact.uniq.inject({}) { |rv, u| rv[u.id] = u; rv }
    @comments = values.select { |a| @users.include?(a.user_id) }
    @comments_by_id = @comments.each_with_object({}) { |c, m| m[c.id] = c }
    @replies = @comments.inject({}) do |memo, comment|
      unless comment.is_a?(Anchor::CommentReply)
        memo[comment] = comment.replies.select {|r| @users.include?(r.user_id) }.
          sort {|a, b| a.created_at <=> b.created_at}
      else
        memo[comment] = []
      end
      memo
    end

    # index the flaggers and repliers for each comment
    @flaggers = @comments.inject({}) do |m, comment|
      m[comment] = comment.grouped_flags.inject({}) do |m2, (reason, flags)|
        m2[reason] = Set.new(flags.map {|flag| @users[flag.user_id]})
        m2
      end
      m
    end
    @repliers = @comments.inject({}) do |m, comment|
      unless comment.is_a?(Anchor::CommentReply)
        m[comment] = comment.replies.inject({}) do |m2, reply|
          m2[reply] = @users[reply.user_id]
          m2
        end
        m
      else
        m[comment] = {}
      end
    end
  end
end
