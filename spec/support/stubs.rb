require 'active_support/core_ext/string' # for String#parameterize

module Stubs
  def stub_person(label, attrs = {})
    connected_networks = attrs.delete(:networks) || [:facebook, :twitter]
    network_profiles = connected_networks.inject({}) do |m, n|
      m.merge!(n => stub_network_profile("#{label}-#{n}-profile", n))
    end
    defaults = {id: 123, async_sync_connected_profiles: nil, connected_networks: connected_networks,
      network_profiles: network_profiles, connected_profiles: network_profiles.values}
    p = stub(label, defaults.merge(attrs))
    p.stubs(:for_network).returns(nil)
    p.stubs(:connected_to?).returns(false)
    connected_networks.each do |n|
      p.stubs(:for_network).with(n).returns(network_profiles[n])
      p.stubs(:connected_to?).with(n).returns(true)
    end
    p
  end

  def stub_user(name, attrs = {})
    first_name, last_name = name.split(' ', 2)
    slug = attrs.delete(:slug) || name.parameterize
    id = attrs.delete(:id) || 123
    facebook_profile = attrs.delete(:facebook_profile) || stub("fb-#{slug}", fbid: "fb#{id}")
    profile_photo = attrs.delete(:profile_photo) || stub("profile_photo-#{slug}", url: '/img/photo.jpg')
    person = attrs.delete(:person) || stub_person("#{slug}-person")
    user = stub(slug, {id: id, name: name, firstname: first_name, lastname: last_name, slug: slug, display_name: name,
      email: "#{slug}@example.com", facebook_profile: facebook_profile,
      profile_photo: profile_photo, inactive?: false, guest?: false, registered?: true, connected?: false,
      profile_url: '//profile', to_param: slug, to_job_hash: {}, person: person, person_id: person.id,
      visitor_id: 'deadbeef', recent_listing_ids: [], touch_last_synced: nil, suggested?: false, autofollowed?: false,
      created_at: Time.zone.now, updated_at: Time.zone.now, state: :registered, web_site_enabled?: false,
      credit_balance: 0.00, full_listing_access?: false, no_listing_access?: false, limited_listing_access?: false,
      seller_listings: [], buyer_orders: [], can_deactivate?: true, has_unfinalized_orders?: false,
      unfinalized_orders: [], to_key: [:id], web_site_enabled: false, listing_access: nil, superuser?: false,
      admin?: false, annotations: [], credited_invite_acceptance_cap: 5,
      total_amount_earnable_for_accepted_invites: 100, person_id: person.id,
      remember_created_at: Time.zone.now, balanced_url: "http://balancedpayments.com/accounts/#{slug}",
      registered_followers: [], registered_followees: [], likes_count: 3,
      deposit_accounts: [], can_reactivate?: true, just_registered?: false, recent_listed_listing_ids: [],
      bio: "It makes me feel like a man when I put a spike into my vein", recent_saved_listing_ids: [] }.
        merge(attrs))
    user.stubs(:for_network).with(:facebook).returns(person.for_network(:facebook)) # XXX: better way?
    person.stubs(:user).returns(user)
    user.class.stubs(model_name: User.model_name)
    user.class.stubs(name: User.name)
    user
  end

  def stub_mailer_user(name, options = {})
    attrs = options.dup
    listings = attrs.delete(:listings) || []
    listing_infos = listings.map { |l| stub("listing-#{l.id}-info", listing: l, photo: l.photos.first) }
    attrs.reverse_merge!(
      visible_listings_count: 87,
      likes_count: 124,
      registered_followers: stub('followers', total_count: 8286),
      representative_listing_infos: listing_infos
    )
    stub_user(name, attrs)
  end

  def stub_listing(title, attrs = {})
    slug = title.parameterize
    photos = attrs.delete(:photos) || [stub_listing_photo(label: "#{slug}-photo")]
    seller = attrs.delete(:seller) || stub_user('Mephistopheles')
    category = attrs.delete(:category) || stub_category('Stuff')
    listing = stub(slug, {id: 123, title: title, slug: slug, to_param: slug, photos: photos, price: 100.00, total_price: 100.00,
      subtotal: 90.00, shipping: 0.00, buyer_fee: 0.00, proceeds: 0.00, seller: seller, seller_id: seller.id,
      tag_ids: [], tags: [], category: category, size_id: nil, size: nil, brand_id: nil, brand: nil,
      handling_duration: 4.days, warnings: [], errors: [], new?: false, sold_by?: false,
      has_been_activated?: true, created_at: Time.zone.now, activated_at: Time.zone.now, state: :active,
      condition: 'Hella Broken', seller_fee: 1.20, buyer_fee: 1.50, likes_count: 1, comments_count: 3, saves_count: 4,
      commentable?: true}.merge(attrs))
    listing.stubs(:sold_by?).with(seller).returns(true)
    listing
  end

  def stub_listing_photo(attrs = {})
    label = attrs.delete(:label) || 'listing-photo'
    file = attrs.delete(:file) || stub('file', medium: stub('medium', url: '/img/medium.jpg'),
                                       large: stub('large', url: '/img/large.jpg'), url: '/image/original.jpg')
    stub(label, {id: 456, file: file, url: '/img/version.jpg', version_url: '/img/version.jpg', image_dimensions: [500, 500]}.merge(attrs))
  end

  def stub_listing_stats(attrs = {})
    views = attrs.delete(:views) || 0
    likes = attrs.delete(:likes) || 0
    OpenStruct.new(attrs.merge(views: views, likes: likes))
  end

  def stub_listing_story(attrs = {})
    type = attrs.delete(:type) || :listing_liked
    imperative = attrs.delete(:imperative) || :love
    types = attrs.delete(:types) || []
    actor = attrs.delete(:actor) ||  stub_user('Walter', id: 1)
    actor_ids = attrs.delete(:actor_ids) || []
    action = attrs.delete(:action) || nil
    users = attrs.delete(:users) || [actor]
    listing = attrs.delete(:listing) || stub_listing('The Ringer')
    photo = attrs.delete(:photo) || stub_listing_photo(label: "#{listing.slug}-photo")
    story = stub('listing-story', {
      type: type, action: action, actor: actor, actor_ids: actor_ids, types: types, listing: listing,
      created_at: Time.now, complete?: true, photo: photo, latest_type_actor_id: [type.to_sym, actor.id],
      latest_imperative_action_actor: [imperative, actor]
    }.merge(attrs))
    story.stubs(:like?).returns(story.type == :listing_liked)
    story.stubs(:users).returns(users)
    story.stubs(:latest_type_actor=)
    story
  end

  def stub_product_card(listing, attrs = {})
    ProductCard.new(listing, attrs)
  end

  def stub_listing_stats_page(listings, options = {})
    orig = listings.map {|l| stub_listing_stats(listing_id: l.id)}
    limit = options.fetch(:limit, 100)
    offset = options.fetch(:offset, 0)
    total = options.fetch(:total, orig.size)
    Ladon::PaginatableArray.new(orig, limit: limit, offset: offset, total: total)
  end

  def stub_listing_feature(attrs = {})
    listing = attrs.delete(:listing)
    unless listing
      title = attrs.delete(:title) || 'listing'
      listing_attrs = attrs.delete(:listing_attrs) || {}
      listing = stub_listing(title, listing_attrs)
    end
    stub("#{listing.slug}-feature", {id: 123, listing: listing}.merge(attrs))
  end

  def stub_order(listing, attrs = {})
    shipment = attrs.delete(:shipment)
    shipping_address = attrs.delete(:shipping_address)
    buyer = attrs.delete(:buyer) || stub_user('Joe Buyer')
    order = stub("#{listing.slug}-order", {id: 123, reference_number: 'abcdef', created_at: 1.day.ago,
      updated_at: 1.hour.ago, class: Order, listing: listing, credit_amount: 5.00,
      total_price: (listing.total_price - 5.00), payment_sid: 'PY0f1dfc88963011e0ad7d1231400042c7',
      confirmed_at: nil, completed_at: nil, return_completed_at: nil, canceled_at: nil,
      to_key: [456], shipping_carrier_key: :ups, buyer: buyer, buyer_id: buyer.id, annotations: [],
      listing_id: listing.id}.merge(attrs))
    order.stubs(:shipment).returns(shipment || stub_shipment(order))
    order.stubs(:bought_by?).returns(false)
    order.stubs(:bought_by?).with(buyer).returns(true)
    order.stubs(:shipping_address).returns(shipping_address || stub_postal_address("Frodo's House"))
    order.class.stubs(name: Order.name)
    order
  end

  def stub_postal_address(name, attrs = {})
    label = name.parameterize
    stub(label, {line1: 'Bag End', line2: '', city: 'Hobbiton', state: 'The Shire', zip: '00000',
      phone: '(000) 000-0000', name: name}.merge(attrs))
  end

  def stub_shipment(order, attrs = {})
    stub("#{order.listing.slug}-shipment", {id: 123, carrier_name: 'ups', tracking_number: '1Z12345E0205271688',
      delivery_status_checked_at: nil, delivered_at: nil, order: order}.merge(attrs))
  end

  def stub_connection(attrs = {})
    label = attrs.delete(:label) || 'connection'
    stub(label, {path_count: 0, signal: 0}.merge(attrs))
  end

  def stub_network_profile(label, network, attrs = {})
    label = label.parameterize
    name = attrs.fetch(:name, 'Roman Polanski')
    first_name, last_name = name.split(/\s+/, 2)
    photo_url = '//photo'
    p = stub("profile-#{label}", {id: 5678, uid: 5678, photo_url: photo_url, typed_photo_url: photo_url,
      name: name, first_name: first_name, last_name: last_name, username: label, network: network,
      profile_url: '//profile', api_follows_count: 10}.merge(attrs))
    p.stubs(:to_ary).returns([p])
    p
  end

  def stub_sort_params
    view.stubs(:sort_order).returns(nil)
    view.stubs(:sort_direction).returns(:asc.to_s)
  end

  def stub_searcher_with_listings(listings, opts = {})
    stub('searcher', {
      :tags => stub(:selected => [], :unselected => []),
      :dimensions => stub(:selected => [], :unselected => []),
      :category => nil,
      :categories => stub(:selected => [], :unselected => []),
      :conditions => stub(:selected => [], :unselected => []),
      :price_ranges => stub(:ordered => []),
      :sizes => stub(:alphabetical => []),
      :brands => stub(:alphabetical => []),
      :any? => listings.any?,
      :all => ListingSearcher::ResultsPage.new(listings, current_page: 1, num_pages: 1, per_page: listings.size),
      :sort_keys => [:date, :price, :rprice, :popular],
      :sort_key => :date,
      :size => listings.count,
      :error => nil,
      :page => 1,
      :num_pages => 5,
      :per_page => 1,
      :total => 5,
      :query => nil,
      :selected_tags => [],
      :selected_dimensions => []
    }.merge(opts))
  end

  def stub_listing_results(user, listings)
    cards = listings.map {|l| ProductCard.new(nil, nil, listing: l)}
    cards.stubs(:user).returns(user)
    cards.stubs(:listings).returns(listings)
    cards.stubs(:product_cards).returns(cards)
    cards
  end

  def stub_category(name, attrs = {})
    slug = name.parameterize
    stub(slug, {id: 123, name: name, slug: slug, dimensions: []}.merge(attrs))
  end

  def stub_tag(name, attrs = {})
    slug = name.parameterize
    stub(slug, {id: 123, name: name, slug: slug}.merge(attrs))
  end

  def stub_paginated_array
    stub('paginated-array', any?: false, current_page: 1, num_pages: 1, limit_value: 25)
  end

  def stub_carrierwave_download(uri, image_path)
    data = File.open(image_path, 'rb') { |f| f.read }
    io = StringIO.new(data)
    uri = URI.parse(uri) unless uri.is_a?(URI)
    io.stubs(:base_uri).returns(uri)
    io
  end

  def stub_carrierwave_download!(uri, image_path)
    Kernel.stubs(:open).with(uri).returns(stub_carrierwave_download(uri, image_path))
  end

  def stub_interest(name, attrs = {})
    label = name.parameterize
    stub(label, {id: 1, name: name}.merge(attrs))
  end

  def stub_paypal_deposit_account(seller, attrs = {})
    attrs.reverse_merge!(user: seller, email: seller.email, default: false)
    stub("paypal-deposit-account-#{attrs[:email]}", attrs)
  end

  def stub_offer(name = 'Free Hat', attrs = {})
    full_attrs = {
      id: 1, name: name, destination_url: 'http://test.copious.com/offers/free-hat',
      info_url: 'http://test.copious.com/info/free-hat',
      amount: 400, minimum_purchase: 500, duration: 10.days.to_i, available: 1000,
      new_users?: true, existing_users?: true, signup: false,
      expires_at: Time.zone.now + 30.days, created_at: Time.zone.now, updated_at: Time.zone.now,
      ab_tag: 'free-hat', descriptor: 'So many free hats!',
      landing_page_headline: 'YOU JUST EARNED A FREE HAT', landing_page_text: "IT'S THE BEST HAT EVAR",
      landing_page_background_photo: 'http://cdn.memegenerator.net/instances/400x/26568933.jpg',
      fb_story_name: 'free hats wuz earned', fb_story_caption: 'this is a pimp hat yea?',
      fb_story_description: "words can't describe this hat", fb_story_image?: true,
      fb_story_image: stub('fb image', url: 'http://cdn.memegenerator.net/instances/400x/26573226.jpg')
    }.merge(attrs)
    stub(name, full_attrs)
  end

  def stub_comment(commenter, text, attrs = {})
    attrs = attrs.reverse_merge(id: "deadbeef", text: text, user_id: commenter.id, created_at: Date.current - 12.hours,
                                flags: [], replies: [], grouped_flags: {}, flagged_by?: false, parent_id: nil,
                                flagged?: false)
    stub("comment-#{attrs[:id]}", attrs)
  end
end

RSpec.configure do |config|
  config.include Stubs
  config.before do
    Airbrake.stubs(:notify)
  end
end
