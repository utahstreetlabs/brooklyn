require 'anchor/models/comment_reply'

class CommentReply < LadonDecorator
  decorates Anchor::Comment

  attr_reader :keywords

  def initialize(decorated, options = {})
    super(decorated)
    @keywords = options[:keywords] || {}
  end

  def to_param
    decorated.id
  end

  def self.create(comment, replier, attrs = {})
    keywords = attrs[:keywords] || {}
    attrs = attrs.except(:keywords)
    attrs[:text] = CommentFormatter.new.format(attrs[:text], keywords, replier)
    r = comment.create_reply(attrs)
    r && new(r, keywords: keywords)
  end
end
