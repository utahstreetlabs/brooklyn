module AcceptanceFactories
  # Find or create a category
  def given_category(name)
    Category.find_or_create_by_name(name)
  end

  def given_feature_lists(*names)
    FeatureList.find_or_create_all_by_name(*names)
  end

  def given_feature_list(name)
    FeatureList.find_or_create_by_name(name)
  end

  def given_condition(name)
    DimensionValue.find_or_create_by_value(name)
  end

  # Find or create a tag.
  def given_tags(*names)
    Tag.find_or_create_all_by_name(*names)
  end

  def given_tag(name, options = {})
    Tag.find_or_create_by_name(name, options)
  end

  def given_size_tag(name)
    Tag.find_or_create_by_name(name, type: 's')
  end

  # Find or create a dimension in a given category. Must provide :category and
  # :values as options.
  def given_dimension(name, options)
    dimension = options.fetch(:category).dimensions.find_or_create_by_name(name)
    options.fetch(:values).each do |value|
      dimension.values.find_or_create_by_value(value)
    end
    dimension
  end

  # Find or create a few listings. Pass a number of hashes for each listing
  # desired.
  #
  # For associations, you should pass a string. The related object will be
  # either associated to the listing or created.
  #
  # Supported associations:
  #   - :category  (name)
  #   - :tags      (names)
  #   - :size      (name)
  #   - :seller    (email)
  #   - :photo     (path to file)
  #   - :condition (condtion)
  def given_listings(*attributes)
    attributes.map do |hash|
      if category = hash.delete(:category)
        hash[:category] = given_category(category)
      end

      if seller = hash.delete(:seller)
        hash[:seller] = User.find_by_email!(seller)
      end

      if photo = hash.delete(:photo)
        photo = ListingPhoto.new(
          :file => File.open(File.expand_path(photo))
        )
      end

      if size = hash.delete(:size)
        hash[:size] = given_size_tag(size)
      end

      if category = hash.delete(:condition)
        hash[:dimension_values] = [given_condition(category)]
      end

      tags = given_tags(hash.delete(:tags) || [])

      state = hash.delete(:state) || 'active'

      listing = FactoryGirl.create("#{state}_listing".to_sym, hash)
      listing.photos << photo if photo
      listing.tags = tags if tags.any?
      listing
    end
  end

  # Shorthand for creating a single listing
  def given_listing(attributes = {})
    given_listings(attributes).first
  end

  def given_order(state, options = {})
    seller_options = options.fetch(:seller, {})
    if seller_options.is_a?(User)
      seller = seller_options
      seller.balanced_url = nil
    else
      seller_options[:balanced_url] = nil
      seller = FactoryGirl.create(:seller, seller_options)
    end

    deposit_account_options = options.fetch(:deposit_account, {}).merge(default: true, user: seller, balanced_url: nil)
    deposit_account_type = deposit_account_options.delete(:type) || :bank_account
    deposit_account = FactoryGirl.create(deposit_account_type, deposit_account_options)

    listing_options = options.fetch(:listing, {})
    if listing_options.is_a?(Listing)
      listing = listing_options
    else
      listing_options[:seller] = seller
      listing = FactoryGirl.create(:active_listing, listing_options)
    end

    buyer_options = options.fetch(:buyer, {})
    if buyer_options.is_a?(User)
      buyer = buyer_options
      buyer.balanced_url = nil
    else
      buyer_options[:balanced_url] = nil
      buyer = FactoryGirl.create(:buyer, buyer_options)
    end

    order_options = options.fetch(:order, {}).merge(buyer: buyer, listing: listing, balanced_debit_url: nil,
      balanced_credit_url: nil, balanced_refund_url: nil)
    FactoryGirl.create("#{state}_order".to_sym, order_options)
  end

  def given_order_cancelled_due_to_non_shipment(options = {})
    order = given_order(:confirmed, options)
    CancelConfirmedUnshippedOrders.cancel_unshipped_order(order)
    CancelledOrder.find(order.id)
  end

  def given_credit(attributes = {})
    trigger_name = attributes.delete(:trigger)
    credit = FactoryGirl.create(:credit, {user: current_user}.merge(attributes))
    credit.create_trigger(trigger_name) if trigger_name
    credit
  end

  def given_credits(*credits)
    credits.map {|a| given_credit(a) }
  end

  def given_offer(attributes = {})
    FactoryGirl.create(:offer, attributes)
  end

  def given_oauth(network, oauth, uid = nil)
    map = oauth
    if oauth == :mock
      map = send("given_#{network}_profile")
      map['uid'] = uid if uid
    end
    Hashie::Mash.new(map)
  end

  def given_user(type, attributes = {})
    network = attributes.delete(:network) || :facebook
    person = attributes.delete(:person) || FactoryGirl.create(:person)
    oauth = given_oauth(network, attributes[:oauth] ? attributes.delete(:oauth) : :mock)
    given_network_profile(person, network, oauth)
    user = FactoryGirl.create(type, attributes.merge(person: person))
    user.add_identity_from_oauth(Network.klass(network), oauth)
    user
  end

  # Create a user who has connected to a network but not yet finished the registration process. Accepts a hash of
  # +User+ attributes. Note: does not actually create a network profile in Rubicon. XXX: do that
  def given_connected_user(attributes = {})
    given_user(:connected_user, attributes)
  end

  # Create a user who has connected to a network and then registered. Accepts a hash of +User+ attributes. Note: does
  # not actually create a network profile in Rubicon. XXX: do that
  def given_registered_user(attributes = {})
    given_user(:registered_user, attributes.merge(balanced_url: nil))
  end

  def given_inactive_user(attributes = {})
    given_user(:inactive_user, attributes.merge(balanced_url: nil))
  end

  def given_shipping_address(user)
    FactoryGirl.create(:shipping_address, user: user)
  end

  # Create a network profile for a person in Rubicon based on either the provided OAuth hash or the default mock
  # OmniAuth one for +network+.
  def given_network_profile(person, network, oauth = :mock)
    oauth = given_oauth(network, oauth)
    if profile = person.for_network(network) && person.user
      profile.update_from_oauth!(person.user, oauth)
    else
      profile = person.create_or_update_profile_from_oauth(network, oauth)
    end
    profile
  end

  def given_directly_invited_profile_from(inviter_profile, options = {})
    profile = given_network_profile(FactoryGirl.create(:person), :facebook, options[:invitee_oauth])
    profile.create_invite_from(inviter_profile)
    profile
  end

  def given_untargeted_invite(inviter)
    Rubicon::UntargetedInvite.find_for_person(inviter.person_id)
  end

  def given_network_follower(person, network, oauth=nil, bidi=false)
    profile = person.for_network(network)
    follower = FactoryGirl.create(:person)
    follower_profile = given_network_profile(follower, network, oauth)
    # don't try to compute follow rank since these followers don't actually exist in the external network
    profile.create_follow(follower_profile, no_rank: true)
    follower_profile.create_follow(profile, no_rank: true) if bidi
    follower_profile
  end

  def given_like(listing, user)
    user.like(listing)
  end

  def given_tag_like(tag, user)
    user.like(tag)
  end

  def given_organic_follow(followee, follower)
    OrganicFollow.create!(:user => followee, :follower => follower)
  end

  def given_comment(listing, commenter, attrs = {})
    listing.comment(commenter, {text: 'This is a comment'}.merge(attrs))
  end

  def given_reply(comment, replier, attrs = {})
    comment.create_reply({text: 'This is a reply', user_id: replier.id}.merge(attrs))
  end

  def given_comment_flag(comment, flagger, attrs = {})
    comment.create_flag({reason: 'spam', description: 'Evil spammer!', user_id: flagger.id}.merge(attrs))
  end

  def given_notifications(date_blocks)
    date_blocks.inject({}) do |nd, kv|
      date = kv[0]
      count = kv[1]
      nd[date] = 1.upto(count).map do |n|
        Lagunitas::Notification.create(:Notification, current_user.id, created_at: (date.to_time + 60*60*n))
      end
      nd
    end
  end

  def given_notification(attrs = {})
    Lagunitas::Notification.create(:Notification, current_user.id, attrs)
  end

  def simulate_purchase(attrs={})
    buyer = attrs[:as] || current_user
    given_order(:complete, buyer: buyer)
  end

  def given_joined_story(joiner, interested)
    #XXXrisingtide: this should queue a story and wait for it to be processed
  end

  def given_interest(name, options = {})
    cover_photo = fixture_file_upload('/hamburgler.jpg', 'image/jpg')
    FactoryGirl.create(:interest, {name: name, onboarding: '1', cover_photo: cover_photo})
  end

  def given_interests(count)
    FactoryGirl.create_list(:interest, count)
  end

  def given_onboarding_interests(count)
    interests = given_interests(count)
    Interest.add_to_onboarding_list!(interests.map(&:id))
    interests
  end

  def given_global_interest
    FactoryGirl.create(:global_interest)
  end

  def given_suggested_user_list(count)
    interest = FactoryGirl.create(:interest)
    FactoryGirl.create_list(:user_suggestion, count, interest: interest)
    interest
  end

  def given_interest_suggestions(user, interests = Interest.all)
    interests.each do |interest|
      # if you are going to be suggested for an interest, you might as well have that interest
      interest.add_to_suggested_user_list!(user)
      user.add_interest_in!(interest)
    end
  end

  def given_collection(hash = {})
    if user = hash.delete(:user)
      hash[:user] = User.find_by_email!(user)
    end
    FactoryGirl.create(:collection, hash)
  end
end

RSpec.configure do |config|
  config.include AcceptanceFactories
end
