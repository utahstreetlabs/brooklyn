module Listings
  class CommentedExhibit < Exhibitionist::Exhibit
    include Exhibitionist::RenderedWithCustom
    attr_reader :comment

    def initialize(listing, comment, viewer, context, options = {})
      super(listing, viewer, context, options)
      @comment = comment
    end

    def collect_facebook_mentions(keywords)
      # Assume all keywords exist in the comment (keywords are all relevant)
      return if keywords.nil?
      mentions = {}
      keywords.each do |key, val|
        mentions[key] = val if val['type'] == 'fb' && CommentFormatter.new.validate_keyword(val, viewer)
      end
      mentions
    end

    def self.create(listing, comment, viewer, context, options = {})
      if options[:confirmation]
        CommentedConfirmationExhibit.new(listing, comment, viewer, context, options)
      elsif options[:modal]
        CommentedModalExhibit.new(listing, comment, viewer, context, options)
      else
        CommentedFeedExhibit.new(listing, comment, viewer, context, options)
      end
    end

    custom_render do |listing|
      listing.options[:extras] || {}
    end
  end

  class CommentedConfirmationExhibit < CommentedExhibit
    custom_render do |listing|
      data = {
        confirmation: Listings::Comments::CommentedWithConfirmationExhibit.new(listing, listing.comment,
          listing.viewer, listing.context, listing.options).render }
      data.merge!(listing.options[:extras]) if listing.options.include?(:extras)
      data
    end
  end

  class CommentedModalExhibit < CommentedExhibit
    custom_render do |listing|
      data = {
        comment: Listings::Modal::CommentsExhibit.new(listing, listing.viewer, listing.context).render,
        mentions: listing.collect_facebook_mentions(listing.options[:keywords]),
        currentUser: listing.viewer.name,
        listingTitle: listing.title }
      data.merge!(listing.options[:extras]) if listing.options.include?(:extras)
      data
    end
  end

  class CommentedFeedExhibit < CommentedExhibit
    custom_render do |listing|
      data = {
        comment: Listings::Comments::CommentedWithFeedExhibit.new(listing, listing.comment, listing.viewer,
          listing.context, listing.options).render,
        mentions: listing.collect_facebook_mentions(listing.options[:keywords]),
        currentUser: listing.viewer.name,
        listingTitle: listing.title }
      data.merge!(listing.options[:extras]) if listing.options.include?(:extras)
      data
    end
  end
end
