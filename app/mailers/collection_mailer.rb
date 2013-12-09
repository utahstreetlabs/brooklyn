class CollectionMailer < MailerBase
  def collection_follow(collection, follower_id)
    @collection = collection
    @follower = User.find(follower_id)
    @follower_listing_infos = @follower.representative_listing_infos(count: 4)
    @owner = collection.owner
    @listing = collection.find_visible_listings.first
    campaign = 'collectionfollow'
    google_analytics source: 'notifications', campaign: campaign, medium: 'email'
    sendgrid_category campaign
    track_usage('email_collection_follow send', username: @owner.slug, collection_name: @collection.slug) do
      setup_mail(:collection_follow, headers: {to: @owner.email}, params: {follower: @follower.name})
    end
  end
end
