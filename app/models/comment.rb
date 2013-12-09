require 'anchor/models/comment'

class Comment < LadonDecorator
  decorates Anchor::Comment

  attr_reader :keywords

  def initialize(decorated, options = {})
    super(decorated)
    @keywords = options[:keywords] || {}
  end

  def to_param
    decorated.id
  end

  def parsed
    @parsed ||= Parsed.new(text)
  end

  def hashtags
    @hashtags ||= begin
      slugs = parsed.select { |n| n.is_a?(Parsed::Hashtag) }.map(&:slug)
      slugs.any? ? Tag.where(slug: slugs) : []
    end
  end

  def self.create(listing, commenter, attrs = {})
    keywords = attrs[:keywords] || {}
    attrs = attrs.except(:keywords)
    attrs[:text] = CommentFormatter.new.format(attrs[:text], keywords, commenter)
    c = listing.anchor_instance.comment(commenter.id, attrs)
    c && new(c, keywords: keywords)
  end

  def self.find(listing, comment_id)
    c = Anchor::Comment.find(listing.id, comment_id)
    c && new(c)
  end

  class Parsed
    include Enumerable

    def initialize(text)
      fragment = Nokogiri::HTML::fragment(text)
      @elements = fragment.children.map do |node|
        if node.is_a?(Nokogiri::XML::Element) && node.name == 'span' && node['data-role'] == 'kw'
          if (klass = CommentNode.for_type(node['data-kw-type']))
            id, slug, name = [:id, :slug, :name].map { |k| node["data-kw-#{k}"] }
            klass.new(id, slug, name)
          end
        elsif node.is_a?(Nokogiri::XML::Text)
          Text.new(node.text)
        else
          Text.new(node.content)
        end
      end
    end

    def each(&block)
      @elements.each(&block)
    end

    class CommentNode
      def self.for_type(type)
        NODE_TYPES[type.to_sym]
      end
    end

    class Text < CommentNode
      def initialize(text)
        @text = text
      end
    end

    class Keyword < CommentNode
      attr_reader :id, :slug, :name
      def initialize(id, slug, name)
        @id, @slug, @name = id, slug, name
      end
    end

    class Hashtag < Keyword
      def initialize(id, slug, name)
        super
        # currently we're only storing the hashtag slug in the id field, not sure why
        @slug ||= id
      end
    end

    class CopiousFollow < Keyword; end
    class FacebookFriend < Keyword; end

    NODE_TYPES = {cf: CopiousFollow, fb: FacebookFriend, tag: Hashtag}
  end
end
