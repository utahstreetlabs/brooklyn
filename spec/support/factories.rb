# XXX: try as hard as possible to get rid of these and use stubs/mocks only

FactoryGirl.define do
  sequence :email do |n|
    "user#{n}@example.com"
  end

  factory :person do
  end

  factory :network_profile, :class => Rubicon::Profile do
    scope "email"
  end

  factory :guest_user, :class => User do
    person
  end

  factory :connected_user, parent: :guest_user do
    email
    firstname "test"
    lastname "user"
    after_create do |user|
      user.stubs(:async_set_profile_photo_from_network)
      Users::AfterConnectionJob.stubs(:import_location)
      user.visitor_id = User.generate_visitor_id
      user.connect!
    end
  end

  factory :registered_user, parent: :connected_user do
    balanced_url "http://balancedpayments.com/accounts/deadbeef"
    after_create do |user|
      user.password = 'test'
      user.password_confirmation = 'test'
      user.register!
      user.password = nil
      user.password_confirmation = nil
      user.admin = false
    end
  end

  factory :seller, parent: :registered_user do
    after_create do |user|
      unless user.balanced_url.present?
        user.create_merchant!(Balanced::PersonMerchantIdentity.new(
          name: user.name,
          street_address: '164 Townsend St #6',
          postal_code: '94107',
          born_on: Date.today,
          phone_number: '(415) 555-1212'
        ))
      end
    end
  end

  factory :buyer, parent: :registered_user do
  end

  factory :inactive_user, parent: :registered_user do
    after_create do |user|
      user.deactivate!
    end
  end

  factory :follow, class: OrganicFollow do
    association :user, factory: :registered_user
    association :follower, factory: :registered_user
  end

  factory :follow_tombstone do
    association :user, factory: :registered_user
    association :follower, factory: :registered_user
  end

  factory :email_account do
    association :user, factory: :registered_user
  end

  factory :contact do
    email_account
    person
  end

  factory :category do
    sequence(:name) {|n| "Category #{n}" }
  end

  factory :tag do
    sequence(:name) {|n| "Tag #{n}" }
  end

  factory :subtag, :class => Tag do
    association :primary_tag, factory: :tag
    sequence(:name) {|n| "Subtag #{n}" }
  end

  factory :size_tag, parent: :tag do
    name 'Medium'
    type 's'
  end

  factory :size_subtag, parent: :subtag do
    name 'One size fits all'
    type 's'
  end

  factory :brand_tag, parent: :tag do
    type 'b'
  end

  factory :feature_list do
    sequence(:name) {|n| "Feature List #{n}" }
  end

  factory :editors_picks_feature_list, parent: :feature_list do
    name "Editor's Picks"
    slug 'editors-picks'
  end

  factory :feature_list_feature, class: ListingFeature do
    association :featurable, factory: :feature_list
    association :listing, factory: :active_listing
  end

  factory :dimension do
    sequence(:name) {|n| "Dimension #{n}" }
    category
  end

  factory :dimension_value do
    sequence(:value) {|n| "Value #{n}" }
  end

  factory :external_listing, :class => ExternalListing do
    sequence(:title) {|n| "External Product #{n}" }
    price 25.00
    category
    description "A listing description"
    association :seller, factory: :seller
    association :source, factory: :listing_source
    after_build do |listing|
      listing.source_image = listing.source.images.first
    end
  end

  factory :incomplete_listing, :class => InternalListing do
    sequence(:title) {|n| "Product #{n}" }
    association :seller, :factory => :seller
  end

  factory :completable_listing, parent: :incomplete_listing do
    description 'OMG its a test item'
    price 25.00
    category
    after_create do |listing|
      listing.photos << FactoryGirl.create(:listing_photo, :listing => listing)
    end
  end

  factory :inactive_listing, :parent => :completable_listing do
    after_create do |listing|
      raise listing.errors.inspect unless listing.complete
    end
  end

  factory :active_listing, :parent => :inactive_listing do
    after_create do |listing|
      listing.activate!
    end
  end

  factory :sold_listing, :parent => :active_listing do
    after_create do |listing|
      listing.sell!
    end
  end

  factory :suspended_listing, :parent => :active_listing do
    after_create do |listing|
      listing.suspend!
    end
  end

  factory :cancelled_listing, :parent => :active_listing do
    after_create do |listing|
      listing.cancel!
    end
  end

  factory :listing_flag do
    association :user, :factory => :registered_user
    association :listing, :factory => :active_listing
  end

  factory :listing_photo do
    file { File.open('spec/support/facebook.gif') }
    association :listing, factory: :active_listing
  end

  factory :listing_offer do
    amount 5.00
    duration 2.days
    association :user, factory: :registered_user
    association :listing, factory: :active_listing
  end

  factory :postal_address do
    sequence(:name) {|n| "Address #{n}" }
    line1 '42 Bedford Ave Apt 23'
    city 'Brooklyn'
    state 'NY'
    zip '11211'
    phone '(718) 555-1234'
    association :user, :factory => :registered_user
  end

  factory :shipping_address, :parent => :postal_address do
    ref_type PostalAddress::RefType::SHIPPING
  end

  factory :return_address, :parent => :postal_address do
    ref_type PostalAddress::RefType::SHIPPING
  end

  factory :shipping_label do
    url 'spec/fixtures/shipping-label.pdf'
    document { File.open('spec/fixtures/shipping-label.pdf') }
    tracking_number '1Z9999999999999999'
    sequence(:tx_id) { |n| "c605aec1-322e-48d5-bf81-b0bb820f9c22-#{n}" }
    expires_at { ShippingLabel.default_expire_after.from_now }
    association :order, factory: :confirmed_order, balanced_debit_url: 'http://balancedpayments.com/transactions/debit'
    after_create do |label|
      FactoryGirl.create(:shipment, order: label.order, tracking_number: label.tracking_number)
    end
  end

  factory :expired_shipping_label, parent: :shipping_label do
    after_create do |label|
      label.expire!
    end
  end

  factory :pending_order, :class => Order do
    association :listing, factory: :active_listing
    association :buyer, factory: :registered_user
  end

  factory :purchaseable_order, parent: :pending_order do
    after_create do |order|
      order.shipping_address = FactoryGirl.create(:shipping_address, user: order.listing.seller)
      order.purchase = Purchase.new(cardholder_name: order.buyer.name, card_number: '5105105105105100',
        expires_on: Date.today + 365, security_code: '123', line1: order.shipping_address.line1,
        line2: order.shipping_address.line2, city: order.shipping_address.city, state: order.shipping_address.state,
        zip: order.shipping_address.zip, phone: order.shipping_address.phone)
    end
  end

  factory :confirmed_order, :parent => :purchaseable_order do
    balanced_debit_url 'http://balancedpayments.com/transactions/debit'
    after_create do |order|
      order.skip_debit = order.balanced_debit_url.present?
      order.confirm!
      order.skip_debit = false
    end
  end

  factory :cancelled_order, parent: :confirmed_order do
    balanced_refund_url 'http://balancedpayments.com/transactions/refund'
    after_create do |order|
      order.skip_refund = order.balanced_refund_url.present?
      order.cancel!
      order.skip_refund = false
    end
  end

  factory :shipment do
    carrier_name 'ups'
    tracking_number '1Z9999999999999999'
    created_at 1.minute.ago
  end

  factory :shipped_order, :parent => :confirmed_order do
    after_create do |order|
      order.create_shipment!(FactoryGirl.attributes_for(:shipment)) unless order.shipment
      order.ship!
    end
  end

  factory :delivered_order, :parent => :shipped_order do
    # this is a bit of a pain, but the shipment has to be created after the order to get a valid order_id
    # so inheritance, then requires that the update to delivered happens after that.
    # otherwise, the call to +ship!+ will fail because it's in the wrong state.
    after_create do |order|
      order.deliver!
    end
  end

  factory :complete_order, :parent => :delivered_order do
    after_create do |order|
      order.complete!
    end
  end

  factory :settled_order, parent: :complete_order do
    balanced_credit_url 'http://balancedpayments.com/transactions/credit'
    after_create do |order|
      unless order.listing.seller.default_deposit_account?
        Factory.create(:bank_account, default: true, user: order.listing.seller)
      end
      order.skip_credit = order.balanced_credit_url.present?
      order.settle!
      order.skip_credit = false
    end
  end

  factory :social_connection do
  end

  factory :credit do
    association :user, factory: :registered_user
    amount 10
  end

  factory :debit do
    amount 10
  end

  factory :offer do
    sequence(:name) {|n| "Offer #{n}" }
    sequence(:descriptor) {|n| "offer #{n}" }
    amount 5.0
    available 2
    duration 60
    sequence(:landing_page_headline) {|n| "Welcome to Copious! Offer #{n}" }
    new_users true
    existing_users true
    fb_story_image { File.open('spec/support/facebook.gif') }
  end

  factory :seller_offer do
    association :seller, factory: :seller
    association :offer
  end

  factory :tag_offer do
    association :tag
    association :offer
  end

  factory :order_rating do
    association :user, factory: :registered_user
    association :order, factory: :complete_order, balanced_debit_url: 'http://balancedpayments.com/transactions/debit',
      balanced_credit_url: 'http://balancedpayments.com/transactions/credit'
  end

  factory :buyer_rating, parent: :order_rating, class: BuyerRating do
  end

  factory :seller_rating, parent: :order_rating, class: SellerRating do
  end

  factory :rt_story, :class => RisingTide::Story do
  end

  factory :api_config do
    association :user, factory: :registered_user
  end

  factory :shipping_option do
    code ShippingOption.active_option_codes.first
    rate ShippingOption.active_option_configs.first.last.rate
    association :listing, factory: :incomplete_listing
  end

  factory :notification do
  end

  factory :interest do
    sequence(:name) {|n| "Interest #{n}" }
    onboarding false
    cover_photo { File.open('spec/support/facebook.gif') }
  end

  factory :global_interest, class: Interest do
    name 'Global'
    onboarding false
    to_create do |instance|
      instance.id = -1
      # ignore cover photo - global doesn't have one
      instance.save!(validate: false)
    end
  end

  factory :user_suggestion do
    association :user, factory: :registered_user
    association :interest
  end

  factory :user_interest do
    association :user, factory: :registered_user
    association :interest
  end

  factory :collection_autofollow do
    association :collection, factory: :collection
    association :interest
  end

  factory :deposit_account do
    default false
    association :user, factory: :registered_user
    balanced_url 'http://balancedpayments.com/bank-accounts/deadbeef'
    after_build do |account|
      account.skip_create = account.balanced_url.present?
    end
    after_create do |account|
      account.skip_create = false
    end
  end

  factory :bank_account, parent: :deposit_account, class: BankAccount do
    name "My Checking"
    number '012-345-7689'
    routing_number '321174851'
  end

  factory :paypal_account, parent: :deposit_account, class: PaypalAccount do
    email
  end

  factory :seller_payment do
    amount 25.00
    # in reality a payment will only be associated with a settled order, but we don't need that for most testing
    # purposes; feel free to pass in an order in any state if you need something different
    association :order, factory: :pending_order
  end

  factory :bank_payment, parent: :seller_payment, class: BankPayment do
    after_build do |payment|
      unless payment.deposit_account &&
             payment.order.listing.seller.default_deposit_account &&
             payment.order.listing.seller.default_deposit_account.is_a?(BankAccount)
        payment.deposit_account = FactoryGirl.create(:bank_account, user: payment.order.listing.seller, default: true)
      end
    end
  end

  factory :paid_bank_payment, parent: :bank_payment do
    after_create do |payment|
      payment.pay!
    end
  end

  factory :rejected_bank_payment, parent: :bank_payment do
    after_create do |payment|
      payment.reject!
    end
  end

  factory :paypal_payment, parent: :seller_payment, class: PaypalPayment do
    after_build do |payment|
      payment.deposit_account ||= payment.order.listing.seller.default_deposit_account
    end
  end

  factory :facebook_u2u_request do
    sequence(:fb_request_id) {|n| "10000000234#{n}" }
    association :user, factory: :registered_user
  end

  factory :facebook_u2u_invite do
    sequence(:fb_user_id) {|n| "10000000000#{n}" }
    sequence(:invite_code) {|n| "abcdefg#{n}" }
    association :request, factory: :facebook_u2u_request
  end

  factory :completed_facebook_u2u_invite, parent: :facebook_u2u_invite do
    association :user, factory: :registered_user
  end

  factory :invite_acceptance do
    sequence(:invite_uuid) {|n| "abcdefg#{n}" }
    sequence(:inviter_id) {|n| n }
    association :user, factory: :registered_user
  end

  factory :secret_seller_item do
    title 'Hamburgler'
    description 'Scary as ever'
    price 99.99.to_d
    condition 'new'
    photo { File.open('spec/fixtures/hamburgler.jpg') }
    association :seller, factory: :registered_user
  end

  factory :feature_flag do
    sequence(:name) {|n| "flag.#{n}" }
    sequence(:description) {|n| "Flag #{n}" }
  end

  factory :listing_source do
    url 'http://example.com/thinger'
    after_build do |source|
      source.images << FactoryGirl.build(:listing_source_image)
    end
  end

  factory :listing_source_image do
    url 'spec/fixtures/hamburgler.jpg'
    height 90
    width 90
  end

  factory :collection do
    sequence(:name) {|n| "Collection #{n}" }
    association :user, factory: :registered_user
  end

  factory :item do
  end

  factory :have do
    item
    association :user, factory: :registered_user
  end

  factory :want do
    max_price 25.00.to_d
    item
    association :user, factory: :registered_user
  end

  factory :dislike do
    association :user, factory: :registered_user
    association :listing, factory: :active_listing
  end
end unless defined?(SPEC_FACTORIES_LOADED); SPEC_FACTORIES_LOADED = true;
