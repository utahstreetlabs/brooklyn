module FeedHelper
  CARD_RENDERERS = {
    ActorCard                    => :actor_card,
    FacebookFeedDialogInviteCard => :fb_feed_dialog_invite_card,
    FacebookFacepileInviteCard   => :fb_facepile_invite_card,
    FollowCard                   => :follow_card,
    ProductCard                  => :product_card,
    PromotionCard                => :promotion_card,
    TagCard                      => :full_tag_card,
  }

  # @option options [Hash] :options passed to the containing element
  def card_feed(feed, options = {})
    content_tag(:ul, options[:feed].merge(id: 'card-feed-container')) do
      safe_join(feed_cards(feed, options))
    end
  end

  # must remain a separate method so that it can be called by the feed controller
  def feed_cards(feed, options = {})
    feed.map do |card|
      send(CARD_RENDERERS[card.class], card, options)
    end
  end

  def link_to_listings_feed_more(options = {})
    path_opt = {limit: options.fetch(:limit, 24), offset: options.fetch(:offset, 0), feed: options[:feed]}
    link_to '', feed_listings_path(path_opt), style: 'display:none', class: 'listing-feed-more'
  end

  def feed_card_comment(comment, viewer)
    ctype = comment_type(comment)
    commenter = User.find(comment.user_id)
    out = []
    out << content_tag(:li, id: "product-card-comment-#{comment.id}", class: 'product-card-comment',
      data: {listing: comment.listing_id, comment: comment.id}) do
      out2 = []
      out2 << content_tag(:a, nil, name: "comment-#{comment.id}")
      out2 << user_avatar_xsmall(commenter, class: 'text-adjacent')
      out2 << content_tag(:div, class: "product-card-#{ctype}-container") do
        out3 = []
        out3 << link_to_user_profile(commenter, class: 'commenter-name')
        out3 << content_tag(:div, full_clean(comment.text), class: "product-card-#{ctype}-text")
        safe_join(out3)
      end
      safe_join(out2)
    end
    safe_join(out)
  end

  def feed_card_comment_header(listing, viewer)
    out = []
    out << content_tag(:li, class: 'product-card-comment see-more', data: {role: 'product-card-comment-header'}) do
      out2 = []
      if (listing.comments_count > 0)
        out2 << link_to_listing(listing, url: {anchor: 'comment'}) do
          out3 = []
          out3 << t('product_card.v4.comment_listing_link_all') << " " if listing.comments_count > 1
          out3 << t('product_card.v4.comment_listing_link',
            comment_count: pluralize(listing.comments_count, t('product_card.v4.comment')))
          safe_join(out3)
        end
      end
      safe_join(out2)
    end
    safe_join(out)
  end

  def feed_header(options = {})
    content_tag(:div, class: 'feed-header-container') do
      content_tag(:div, class: 'feed-header') do
        out = []
        out << content_tag(:h1, t('shared.welcome_headers.feed.logged_in.title'))
        out << content_tag(:p, t('shared.welcome_headers.feed.logged_in.description_html'))
        safe_join(out)
      end
    end
  end
end
