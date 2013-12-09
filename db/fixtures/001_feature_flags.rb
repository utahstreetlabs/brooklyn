# The enabled attribute is ignored when seeding staging and production so that when the flag is created it defaults to
# being disabled. Flags will be turned on manually in those environments, and these seeds will not override those manual
# changes.
#
# For development and test environments, the enabled attribute is respected. When working on a feature that is not
# ready for other developers to use, you can set enabled to false here. Once it's ready for others to see, change the
# value to true.

flags = [
  {name: 'auth.policy.any', description: 'Force users to sign up or log in upon taking any action', enabled: true},
  {name: 'auth.policy.immediate', description: 'Force users to sign up or log in immediately', enabled: false},
  {name: 'autologin', description: 'Automatically log in users who are logged into Facebook', enabled: true},
  {name: 'boo', description: 'Enable the Copious Boo-splosion', enabled: true},
  {name: 'client.google_analytics', description: 'Track browser events with Google Analytics', enabled: true},
  {name: 'client.hello_society_tracking', description: '', enabled: true}, #XXX: remove?
  {name: 'client.optimizely', description: '', enabled: true}, #XXX: remove?
  {name: 'client.tracking', description: 'Enable client side tracking (ie, Mixpanel)', enabled: true},
  {name: 'client.typekit', description: 'Enable typekit', enabled: true},
  {name: 'collections.add', description: 'Allow users to add collections', enabled: true},
  {name: 'collections.edit', description: 'Allow users to edit collections', enabled: true},
  {name: 'collections.follow', description: 'Allow users to follow collections', enabled: true},
  {name: 'collections.have', description: 'Allow users to indicate that they have listed items for sale',
   enabled: true},
  {name: 'collections.page', description: 'Enable the collections page and associated UI elements', enabled: true},
  {name: 'collections.save_listing', description: 'Allow users to save listings to collections', enabled: true},
  {name: 'collections.unsave_listing', description: 'Allow users to remove listings from collections', enabled: true},
  {name: 'collections.want', description: 'Allow users to indicate that they want items', enabled: true},
  {name: 'collections.add_listing_card', description: 'Show an "add listing" card on collection pages the user owns',
   enabled: true},
  {name: 'credits.sign_up', description: 'Enable signup credits', enabled: true},
  {name: 'email.connection_digest', description: 'Send connection digest email', enabled: false},
  {name: 'feed.follow_card.fb', description: 'Include a Facebook follow card in the feed', enabled: false},
  {name: 'feed.invite_card.fb_feed_dialog', description: 'Include a Facebook Feed Dialog invite card in the feed',
   enabled: false},
  {name: 'feed.invite_card.fb_u2u_request', description: 'Include a Facebook Facepile invite card in the feed',
   enabled: false},
  {name: 'feed.product_card.comments', description: 'Show comments on the back of product cards in the feed',
   enabled: false},
  {name: 'feed.product_card.listing_modal', description: 'Enable listing modal for product card', enabled: true},
  {name: 'feed.promotion_card.secret_seller', description: 'Display the secret seller promo card', enabled: false},
  {name: 'feed.promotion_card.ios', description: 'Display the iOS promo card', enabled: false},
  {name: 'feed.removal', description: 'Allow feed cards to be removed by the user', enabled: true},
  {name: 'feedback', description: 'Feedback system', enabled: false},
  {name: 'hamburger', description: 'Use left-nav layout with hamburger control', enabled: true},
  {name: 'hamburger.auto', description: 'Auto-opening and auto-closing of hamburger nav', enabled: false},
  {name: 'history_manager', description: 'History state and URL manipulation', enabled: true},
  {name: 'home.logged_in.collection_carousel',
   description: '048: Show collection carousel on LIH',
   enabled: true},
  {name: 'home.logged_in.featured_experiment',
   description: '049: Test trending vs featured listings on LIH',
   enabled: false},
  {name: 'home.logged_in.hot_or_not',
   description: '063a: Show hot or not modal on LIH',
   enabled: true},
  {name: 'home.logged_in.popular_experiment',
   description: '046: Test feed vs trending listings on LIH',
   enabled: false},
  {name: 'home.logged_in.trending_experiment',
   description: 'Test normalized trending listings sort on LIH',
   enabled: false},
  {name: 'home.logged_out.popular_experiment',
   description: '044: Test graphic vs trending listings on LOH',
   enabled: false},
  {name: 'horizontal_browse', description: '050: Horizontal browse with filter and sort dropdowns', enabled: false},
  {name: 'infinite_scroll_history', description: '', enabled: true},
  {name: 'invites.bar', description: 'Display the invite bar', enabled: false},
  {name: 'invites.custom_modal', description: 'Use the custom invite modal', enabled: true},
  {name: 'listings.comments.typeahead', description: 'Enable #hashtag and @mention with typeahead in listing comments',
   enabled: true},
  {name: 'listings.external', description: 'Allow users to list items from external sources', enabled: true},
  {name: 'listings.external.bookmarklet', description: 'Display bookmarklet to add listings from an external source',
   enabled: true},
  {name: 'listings.price_alert',
   description: '060: Allow users to save price alerts for listings',
   enabled: true},
  # recommend and save to collections are mutually exclusive
  {name: 'listings.recommend', description: 'Allow users to recommend products to others', enabled: false},
  {name: 'listings.save_to_collection',
   description: 'Allow users to add listings to collections during listing creation',
   enabled: true},
  {name: 'make_an_offer', description: 'Allow users to make offers on listings', enabled: false},
  {name: 'networks.facebook.notifications.action.announce', description: '', enabled: true},
  {name: 'networks.facebook.notifications.action.friend_follow', description: '', enabled: true},
  {name: 'networks.facebook.notifications.action.friend_like', description: '', enabled: true},
  {name: 'networks.facebook.notifications.action.friend_comment', description: '', enabled: true},
  {name: 'networks.facebook.open_graph.object.listing', description: 'Enable open graph actions for listings',
   enabled: true},
  {name: 'networks.facebook.open_graph.object.tag', description: 'Enable open graph actions for tags',
   enabled: true},
  {name: 'networks.facebook.open_graph.object.user', description: 'Enable open graph actions for users',
   enabled: true},
  {name: 'notifications.layout.v2', description: '034c: Enable new notification layout', enabled: true},
  {name: 'onboarding.autofollow_collections', description: 'Autofollow collections based on interests for users',
   enabled: true},
  {name: 'onboarding.create_profile_modal', description: '057c: Use a modal for the create profile form.', enabled: true},
  {name: 'onboarding.skip_interests', description: '057a: Skip interests onboarding', enabled: true},
  {name: 'onboarding.follow_friends_modal', description: '057b: Use the new onboarding step for fb users', enabled: true},
  {name: 'onboarding.tutorial_bar', description: 'Display the tutorial bar to new users', enabled: false},
  {name: 'search_facet_history', description: '', enabled: true},
  {name: 'signup.entry_point.fb_oauth_dialog',
   description: '055: Enter signup flow from FB OAuth dialog rather than signup modal',
   enabled: false},
  {name: 'signup.recaptcha', description: 'Require captcha during signup', enabled: true},
  {name: 'user.autofollow', description: 'Autofollow users', enabled: false}, # XXX still used?
  {name: 'user.scheduled_follows',
   description: 'Enable scheduled follows for new users',
   enabled: true},
]

FeatureFlag.seed :name,
  if Rails.env.staging? || Rails.env.production?
    flags.map { |f| f.except(:enabled) }
  else
    flags
  end

FeatureFlag.delete_all(name: 'listings.external_bookmarklet') # renamed
FeatureFlag.delete_all(name: 'networks.facebook.open_graph.action.object.listing') # renamed
FeatureFlag.delete_all(name: 'networks.facebook.open_graph.action.object.tag') # renamed
FeatureFlag.delete_all(name: 'networks.facebook.open_graph.action.object.user') # renamed
FeatureFlag.delete_all(name: 'networks.facebook.open_graph.action.post.ug_photos')# removed
FeatureFlag.delete_all(name: 'networks.facebook.open_graph.action.sell.ug_photos')# removed
FeatureFlag.delete_all(name: 'signup.modal.immediate') # renamed
FeatureFlag.delete_all(name: 'onboarding.follow_friends') # removed
FeatureFlag.delete_all(name: 'force_registration') # removed
FeatureFlag.delete_all(name: 'collections.save_listing_v2') # removed

if Rails.env.development?
#  Client features cause network connections to be made from the browser to external sites. If your network is crappy
#  (eg if you are on a plane), you may want to turn those features off.
#
# FeatureFlag.update_all({enabled: false}, name: 'client.google_analytics')
# FeatureFlag.update_all({enabled: false}, name: 'client.hello_society_tracking')
# FeatureFlag.update_all({enabled: false}, name: 'client.optimizely')
# FeatureFlag.update_all({enabled: false}, name: 'client.tracking')
# FeatureFlag.update_all({enabled: false}, name: 'client.typekit')
elsif Rails.env.test? || Rails.env.integration?
  FeatureFlag.update_all({enabled: false}, name: 'client.google_analytics')
  FeatureFlag.update_all({enabled: false}, name: 'client.hello_society_tracking')
  FeatureFlag.update_all({enabled: false}, name: 'client.optimizely')
  FeatureFlag.update_all({enabled: false}, name: 'client.tracking')
  FeatureFlag.update_all({enabled: false}, name: 'client.typekit')
  FeatureFlag.update_all({enabled: false}, name: 'onboarding.create_profile_modal')
  # many tests expect this to be on
  FeatureFlag.update_all({enabled: true},  name: 'auth.policy.immediate')
  # when this is on it confuses a bunch of other LIH tests. we can enable it whenever we need it for specific tests.
  FeatureFlag.update_all({enabled: false}, name: 'home.logged_in.hot_or_not')
end

unless Rails.env.staging? || Rails.env.production?
  FeatureFlag.all.each { |f| f.update_column(:admin_enabled, f.enabled) }
end
