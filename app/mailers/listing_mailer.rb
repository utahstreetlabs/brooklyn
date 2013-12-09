class ListingMailer < MailerBase
  include ListingsHelper

  def comment_flagged_for_admin(listing, comment_id, flag_attrs)
    @listing = listing
    @comment = listing.find_comment(comment_id) or
      raise SendModelMail::RetryableFailure.new("Comment #{comment_id} for listing #{listing.id} not found")
    @commenter = User.where(id: @comment.user_id).first
    @flag = attrs_hash(flag_attrs)
    @flagger = User.where(id: flag_attrs[:user_id]).first
    setup_mail(:comment_flagged_for_admin, headers: {to: Brooklyn::Application.config.email.to.info})
  end

  def activated(listing, user_attrs)
    @listing = listing
    @user = attrs_hash(user_attrs)
    campaign = 'listingcreate'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:activated, headers: {to: user_attrs[:email]}, params: {seller: listing.seller.name})
  end

  def seller_welcome(listing)
    @listing = listing
    campaign = 'firstlisting'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:seller_welcome, headers: {to: listing.seller.email}, params: {name: listing.seller.name})
  end

  def featured(listing)
    @listing = listing
    campaign = 'listingfeatured'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:featured, headers: {to: listing.seller.email}, params: {seller: listing.seller.firstname})
  end

  def shared(listing, sharer_id, network)
    @listing = listing
    @sharer = User.find(sharer_id)
    @network = network.to_sym
    campaign = "#{network}share"
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:shared, headers: {to: listing.seller.email},
      params: {name: @sharer.name, network: I18n.t(:name, scope: [:networks, network])})
  end

  def commented(listing, commenter_id, comment_id)
    @listing = listing
    @commenter = User.find(commenter_id)
    @comment = listing.find_comment(comment_id) or
      raise SendModelMail::RetryableFailure.new("Comment #{comment_id} for listing #{listing.id} not found")
    campaign = 'listingcomment'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    track_usage('email_comment send', commenter: @commenter.slug, listing: @listing.slug) do
      setup_mail(:commented, headers: {to: listing.seller.email}, params: {commenter: @commenter.name})
    end
  end

  def replied(listing, commenter_id, comment_id, replier_id, reply_id)
    @listing = listing
    @commenter = User.find(commenter_id)
    @comment = listing.find_comment(comment_id) or
      raise SendModelMail::RetryableFailure.new("Comment #{comment_id} for listing #{listing.id} not found")
    @replier = User.find(replier_id)
    @reply = listing.find_comment(reply_id) or
      raise SendModelMail::RetryableFailure.new("Reply #{reply_id} for listing #{listing.id} not found")
    campaign = 'listingcommentreply'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    track_usage('email_reply send', replier: @replier.slug, commenter: @commenter.slug, listing: @listing.slug) do
      setup_mail(:replied, headers: {to: @commenter.email}, params: {replier: @replier.name, listing: @listing.title})
    end
  end

  def mentioned(listing, commenter_id, comment_id, mentioned_id)
    @listing = listing
    @commenter = User.find(commenter_id)
    @comment = listing.find_comment(comment_id) or
      raise SendModelMail::RetryableFailure.new("Comment #{comment_id} for listing #{listing.id} not found")
    @mentioned = User.find(mentioned_id)
    campaign = 'listingmention'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    tracking_params = {mentionee: @mentioned.slug, mentioner: @commenter.slug, listing: @listing.slug}
    track_usage('email_mention send', tracking_params) do
      setup_mail(:mentioned, headers: {to: @mentioned.email},
                 params: {commenter: @commenter.name, listing: @listing.title})
    end
  end

  def liked(listing, liker_id)
    @listing = listing
    @liker = User.find(liker_id)
    @liker_listing_infos = @liker.representative_listing_infos(count: 4)
    campaign = 'listinglike'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    track_usage('email_like send', liker: @liker.slug, listing: @listing.slug) do
      setup_mail(:liked, headers: {to: listing.seller.email}, params: {liker: @liker.name, listing: @listing.title})
    end
  end

  def saved(listing, collection_id)
    @listing = listing
    @collection = Collection.find(collection_id)
    @saver = @collection.owner
    @saver_listing_infos = @saver.representative_listing_infos(count: 4)
    campaign = 'listingsave'
    google_analytics source: 'notifications', campaign: campaign, medium: 'email'
    sendgrid_category campaign
    track_usage('email_listing_save send', username: @saver.slug, collection_name: @collection.slug) do
      setup_mail(:saved, headers: {to: listing.seller.email}, params: {saver: @saver.name})
    end
  end
end
