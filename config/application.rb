require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(:assets => %w(development test))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

# Bundler >= 1.0.10 uses Psych YAML, which is broken, so fix that.
# https://github.com/carlhuda/bundler/issues/1038
YAML::ENGINE.yamler = 'syck'

require 'syslog' # need constants for configuration

module Brooklyn
  class Application < Rails::Application
    config.time_zone = 'America/Los_Angeles'
    config.encoding = "utf-8"
    # if you change filter parameters, be sure to change the list in config/initializers/airbrake.rb as well
    config.filter_parameters += [:password, :card_number, :'expires_on(1i)', :'expires_on(2i)', :'expires_on(3i)',
                                 :security_code]
    config.action_view.field_error_proc = Proc.new{ |html_tag, instance| html_tag }
    config.autoload_paths += %W(#{config.root}/app/contexts)
    config.autoload_paths += %W(#{config.root}/app/exhibits)
    config.autoload_paths += %W(#{config.root}/app/hooks)
    config.autoload_paths += %W(#{config.root}/app/jobs)
    config.autoload_paths += %W(#{config.root}/app/searchers)
    config.autoload_paths += %W(#{config.root}/app/presenters)
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += %W(#{config.root}/app/controller_observers)
    config.autoload_paths += %W(#{config.root}/app/messages)
    config.assets.paths += %W(#{config.root}/app/assets/templates #{config.root}/vendor/assets/javascripts)
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '**', '*.{rb,yml}')]
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '**', '**', '*.{rb,yml}')]
    config.active_record.observers = :listing_observer, :listing_flag_observer, :tag_observer, :offer_session_observer,
      :index_listing_observer, :index_tag_observer, :visitor_session_observer,
      :person_observer, :profile_session_observer, :identity_observer
    config.log_weasel.key = 'BROOKLYN'

    require 'rack/multipart_related'
    config.middleware.use Rack::MultipartRelated

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Change the path that assets are served from
    # config.assets.prefix = "/assets"

    config.assets.use_jquery_cdn = false

    config.assets.bucket = "utahstreetlabs-assets-#{Rails.env}"

    # Generate digests for assets URLs.
    config.assets.digest = true

    # JS manifests
    config.assets.precompile += [
      :bookmarklet,
      :bootstrap,
      :admin,
      :connect_invites,
      :connect_who_to_follow,
      :application,
      :dashboard,
      :email_account_show,
      :facebook,
      'facebook/connect',
      'gatekeeper',
      :homepage_logged_in,
      :invites,
      :invites_modules_email,
      :invites_modules_facebook,
      :listings_external_create,
      :listings_external_collections,
      :listings_form,
      :listings_edit,
      :listings_external_bookmarklet,
      :listings_external_bookmarklet_complete,
      :listings_purchase_shipping,
      :listings_purchase_payment,
      :listings_show,
      :login,
      :notifications,
      :profile_show,
      :sdk,
      'search_browse/browse',
      :settings_networks,
      :settings_profile,
      :settings_seller,
      :settings_shipping_addresses,
      :signup,
      :signup_invite_shares,
      :signup_buyer
    ].map {|m| "#{m}.js"}

    # CSS manifests
    config.assets.precompile += [
      'jquery.wysiwyg',
      'jquery.countdown',
      'admin',
      'application',
      'bootstrap_and_overrides',
      'bootstrap-datepicker',
      'bootstrap-combobox',
      'bootstrap-combobox-local',
      'browser_specific',
      'connect',
      'homepage_logged_in',
      'invites',
      'product_listing',
      'signup',
      'homepage_logged_out',
      'responsive',
      'logged_out'
    ].map {|m| "#{m}.css"}

    # Copious services

    config.services  = OpenStruct.new(timeout: 2000)
    config.lagunitas = OpenStruct.new(host: '127.0.0.1', port: 4000)
    config.anchor    = OpenStruct.new(host: '127.0.0.1', port: 4010, timeout:
      OpenStruct.new(liked: 5000))
    config.flyingdog = OpenStruct.new(host: '127.0.0.1', port: 4070)
    config.redhook   = OpenStruct.new(host: '127.0.0.1', port: 4020, stub: false, host_count: 2)
    config.rubicon   = OpenStruct.new(host: '127.0.0.1', port: 4030)
    config.rising_tide   = OpenStruct.new(
      # the redis that maps user ids to shard keys in the old feed system
      # XXX: remove when the new feed system ships
      shard_config: OpenStruct.new(host: '127.0.0.1', port: 6379),
      # the redis storing data for active users
      active_users: OpenStruct.new(host: '127.0.0.1', port: 6379),
      # the redis storing stories in the old feed system
      stories: OpenStruct.new(host: '127.0.0.1', port: 6379),
      # redii storing feeds
      card_feeds: OpenStruct.new(
        # feeds in the new feed system
        everything_card_feed: OpenStruct.new(host: '127.0.0.1', port: 6379),
        feed_1: OpenStruct.new(host: '127.0.0.1', port: 6379)
      ),
      # host/port for the feed building DRPC service
      drpc: OpenStruct.new(
        servers: "127.0.0.1:4050",
        timeout: 5,
        # don't retry - 10s would be an insane amount of time to wait for a  feed
        # build, we should just serve the curated feed after 5
        retries: 0)
      )
    config.pyramid   = OpenStruct.new(host: '127.0.0.1', port: 4060)

    # Copious URLs

    config.urls = OpenStruct.new(
      terms: 'http://help.copious.com/customer/portal/articles/82466-copious-terms-of-use',
      privacy_policy: 'http://help.copious.com/customer/portal/articles/82465-copious-privacy-policy',
      help: 'http://help.copious.com/',
      email: 'http://help.copious.com/customer/portal/emails/new',
      feedback: 'http://help.copious.com/customer/portal/emails/new',
      listing_guidelines: 'http://help.copious.com/customer/portal/articles/90492-what-can-i-sell-on-copious-',
      transaction_policy: 'http://help.copious.com/customer/portal/articles/82473-copious-transaction-policy',
      fees_explanation: 'http://help.copious.com/customer/portal/articles/85258-are-there-listing-fees',
      payment_faq: 'http://help.copious.com/customer/portal/topics/37425-payment/articles',
      payment_details: 'http://help.copious.com/customer/portal/topics/37425-payment/articles',
      order_info: 'http://help.copious.com/customer/portal/topics/37545-order-management-/articles',
      shipping_calculator: 'http://shipgooder.com/',
      prepaid_shipping_help: 'http://help.copious.com/customer/portal/articles/610477-how-does-copious-simple-ship-work-',
      prepaid_shipping_schedule_pickup: 'https://tools.usps.com/go/ScheduleAPickupAction!input.action',
      instagram: 'http://help.copious.com/customer/portal/articles/383848-how-do-i-use-instagram-',
      marketplace_fee: 'http://help.copious.com/customer/portal/articles/85264-what-are-the-seller-s-fees-',
      payout_account: 'http://help.copious.com/customer/portal/articles/710963-balanced-benefits',
      invite_offer_details: 'http://help.copious.com/customer/portal/articles/765244-invite-referral-credits',
      secret_seller_faq: 'http://help.copious.com/customer/portal/articles/901260-secret-seller'
    )

    config.banners = OpenStruct.new(
      # banner options:
      #
      # image: the url or path of an image asset as defined by image_tag()
      # link: a url or path as defined by link_to(), or a proc evaluated in the context of a view context object
      #   (has access to all view helpers) returning same (optional)
      # target: the target window of the link (optional, defaults to the current window)
      #
      # one banner that shows up on the logged-in home page
      home: OpenStruct.new(
        # image: 'landing/banner/home/holiday.jpg',
        # link: proc { browse_for_sale_path(path_tags: 'festivus') }
      ),
      # one banner that shows up on the create listing page
      create_listing: OpenStruct.new(
      ),
      # banners keyed by user slug that show up on public profile pages
      profile: {
        # 'mr-brad-goreski' => OpenStruct.new(
        #  image: 'landing/banner/profile/mr-brad-goreski.jpg',
        #  link: 'http://help.copious.com/customer/portal/articles/758133-charity-shop-for-a-cause-with-brad-goreski',
        #  target: '_blank'
        # ),
      },
      # search_browse banners show up on directly-accessed tag landing pages only; they are ignored when tags are
      # selected during faceted search and when multiple-tag pages are accessed directly.
      search_browse: {
      }
    )

    config.invite_bar = OpenStruct.new(
      # do not show the invite bar if the viewer has had this many U2U invites accepted already
      max_acceptances: 10,
    )

    config.invite_modal = OpenStruct.new(
      # maximum number of users to suggest in the invite modal
      max_suggestions: 50,
    )

    config.onboarding_follow = OpenStruct.new(
      # maximum number of facebook friends to suggest in the onboarding follow mfs
      max_suggestions: 50,
    )

    # Copious API

    config.api = OpenStruct.new(token: '73a9d85e53c9ccecc0b5268dbf05707b4102787a')

    # File storage

    config.files = OpenStruct.new(
      s3: OpenStruct.new(bucket: "utahstreetlabs-#{Rails.env}")
    )

    # Balanced payment service

    config.balanced = OpenStruct.new(
      api_key: OpenStruct.new(
        secret: 'YOUR_SECRET'
      ),
      marketplace_bank_accounts: [
        OpenStruct.new(
          name: '',
          number: '',
          last_four: '',
          routing_number: ''
        )
      ],
      connection_timeout: 10,
      read_timeout: 15 # create bank account and card take a long, long time
    )

    # JanRain RPXNow (contact import)

    config.rpxnow = OpenStruct.new(
      api_key: '',
      domain: ''
    )

    # Aviary (photo manipulation)
    config.aviary = OpenStruct.new(
      key: '',
      secret: ''
    )

    # stamps.com (prepaid shipping)
    config.stamps = OpenStruct.new(
      integration_id: '',
      username: '',
      password: '',
      use_test_environment: true,
      open_timeout: 5, # seconds
      read_timeout: 10, # seconds
      # where cached versions of shipping label documents are stored during the download process
      download_cache_dir: Rails.root.join('tmp'),
      # stamps.com rate information corresponding to our shipping options
      rates: {
        # these need to be hashes
        extra_small_box: {
          weight_oz: 9,
          service_type: 'US-FC',
          package_type: 'Package',
        },
        small_box: {
          service_type: 'US-PM',
          package_type: 'Small Flat Rate Box',
        },
        medium_box: {
          service_type: 'US-PM',
          package_type: 'Flat Rate Box',
        },
        medium_flat: {
          service_type: 'US-PM',
          package_type: 'Flat Rate Box',
        },
        large_box: {
          service_type: 'US-PM',
          package_type: 'Large Flat Rate Box',
        }
      }
    )

    # Redis

    config.redis = OpenStruct.new(
      resque: OpenStruct.new(host: '127.0.0.1', port: 6379),
      cache: OpenStruct.new(host: '127.0.0.1', port: 6379),
      vanity: OpenStruct.new(host: '127.0.0.1', port: 6379, db: 0)
   )

    # Jobs

    config.jobs = OpenStruct.new(
      stories: OpenStruct.new(batch_size: 500, batch_blacklist: []),
      email_listing_activated_blacklist: []
    )

    # SendGrid (email)

    config.sendgrid = OpenStruct.new(
      address: 'smtp.sendgrid.net',
      port: 587,
      domain: 'copious.com',
      username: '',
      password: ''
    )

    # Amazon Web Services

    config.aws = OpenStruct.new(
      access_key_id: '',
      secret_access_key: '',
      region: 'us-east-1'
    )

    # Copious email addresses

    config.email = OpenStruct.new(
      from: OpenStruct.new(
        noreply: '',
        name: 'Copious'
      ),
      to: OpenStruct.new(
        help: 'help@copious.com', # for end users
        info: 'info@copious.com', # for system-level messages
        paypal_payments: 'pp-payments@copious.com',
        offer: 'offer@copious.com', # for listing offers,
        secret_seller: 'secretseller@copious.com'
      )
    )

    # Google Analytics

    config.google_analytics = OpenStruct.new(account_id: '')

    # Copious signal

    config.signal = OpenStruct.new(
      connection_weights: OpenStruct.new(
        facebook_friend: 4,
        usl_follower: 2,
        usl_followee: 1
      )
    )

    # Search (solr)

    config.search = OpenStruct.new(
      commit_on_write: false
    )

    # Profile photos

    config.profile_photo = OpenStruct.new(
      default_path: '/assets/icons/profile_photo',
      default_name: '__default__.png'
    )

    # Application session

    config.session = OpenStruct.new(
      timeout_in: 1.hour,
      remember_for: 2.weeks
    )

    # Listing features

    config.listings = OpenStruct.new(
      browse: OpenStruct.new(
        per_page: 36,
        displayed_tags: 15,
        new_arrivals_since: 5.days
      ),
      more_like_this: OpenStruct.new(
        min_price_factor: 0.5,
        max_price_factor: 3.0
      ),
      purchase: OpenStruct.new(
        expire: 900
      ),
      modal: OpenStruct.new(
        thumbnails: OpenStruct.new(
          count: 7
        ),
        comments: OpenStruct.new(
          count: 10
        )
      )
    )

    # Product pricing

    config.pricing = OpenStruct.new(
      minimum: 1.0,
      schemes: [
        OpenStruct.new(version: 1, seller_fee_variable: 0.035),
        OpenStruct.new(version: 2, seller_fee_variable: 0.035, seller_fee_fixed: 0.4, buyer_fee_variable: 0.06),
        OpenStruct.new(version: 3, seller_fee_variable: 0.035, buyer_fee_variable: 0.06)
      ]
    )

    # Shipping carriers

    config.shipping = OpenStruct.new(
      active: [:ups, :usps],
      ups: OpenStruct.new(
        name: 'UPS',
        klass: 'UPS',
        url: 'http://www.ups.com',
        credentials: OpenStruct.new(
          key: '',
          # UPS appears to not check the user / pass, even though they are required.
          login: 'login',
          password: 'password'
        )
      ),
      usps: OpenStruct.new(
        name: 'USPS',
        klass: 'USPS',
        url: 'http://www.usps.com',
        credentials: OpenStruct.new(
          login: '',
          password: ''
        )
      ),
      labels: OpenStruct.new(
        expire_after: 7.days
      )
    )

    # Prepaid shipping options

    config.prepaid_shipping = OpenStruct.new(
      active: [
        :extra_small_box,
        :small_box,
        :medium_box,
        :medium_flat,
        :large_box
      ],
      extra_small_box: OpenStruct.new(
        rate: 3.00.to_d,
        basic_image_url: 'icons/prepaid-shipping/xsmall/basic.jpg',
        step2_image_url: 'icons/prepaid-shipping/xsmall/step2.jpg',
        step3_image_url: 'icons/prepaid-shipping/xsmall/step3.jpg',
        pickup_schedulable: false
      ),
      small_box: OpenStruct.new(
        rate: 5.35.to_d,
        basic_image_url: 'icons/prepaid-shipping/small/basic.jpg',
        step2_image_url: 'icons/prepaid-shipping/small/step2.jpg',
        step3_image_url: 'icons/prepaid-shipping/small/step3.jpg',
        pickup_schedulable: true
      ),
      medium_box: OpenStruct.new(
        rate: 11.35.to_d,
        basic_image_url: 'icons/prepaid-shipping/medium-cube/basic.jpg',
        step2_image_url: 'icons/prepaid-shipping/medium-cube/step2.jpg',
        step3_image_url: 'icons/prepaid-shipping/medium-cube/step3.jpg',
        pickup_schedulable: true
      ),
      medium_flat: OpenStruct.new(
        rate: 11.35.to_d,
        basic_image_url: 'icons/prepaid-shipping/medium-box/basic.jpg',
        step2_image_url: 'icons/prepaid-shipping/medium-box/step2.jpg',
        step3_image_url: 'icons/prepaid-shipping/medium-box/step3.jpg',
        pickup_schedulable: true
      ),
      large_box: OpenStruct.new(
        rate: 15.45.to_d,
        basic_image_url: 'icons/prepaid-shipping/large/basic.jpg',
        step2_image_url: 'icons/prepaid-shipping/large/step2.jpg',
        step3_image_url: 'icons/prepaid-shipping/large/step3.jpg',
        pickup_schedulable: true
      )
    )

    # Application event tracking

    config.tracking = OpenStruct.new(
      adroll: OpenStruct.new(
        adv_id: '',
        pix_id: ''
      ),
      experiments: [
        :logged_in_home,
        :logged_in_home_featured,
        :logged_in_home_hot_or_not,
        :logged_in_home_trending_normalized,
        :logged_out_home,
        :signup_entry_point
      ],
      mixpanel: OpenStruct.new(
        token: '',
        test: false
      ),
      google: OpenStruct.new(
        adwords: OpenStruct.new(
          signup: OpenStruct.new(
            conversion_id: 0,
            conversion_label: ''
          ),
          newlisting: OpenStruct.new(
            conversion_id: 0,
            conversion_label: ''
          ),
          startlisting: OpenStruct.new(
            conversion_id: 0,
            conversion_label: ''
          ),
          firstlisting: OpenStruct.new(
            conversion_id: 0,
            conversion_label: ''
          ),
          registration: OpenStruct.new(
            conversion_id: 0,
            conversion_label: ''
          ),
          purchase_complete: OpenStruct.new(
            conversion_id: 0,
            conversion_label: ''
          ),
        )
      ),
      xanet: OpenStruct.new(
        id: '0',
        val: '0.00'
      ),
      optimal: OpenStruct.new(
        id: '0'
      ),
      events: OpenStruct.new(
        address_book_import: 'upload address book',
        flag_listing: 'report listing',
        cancel_order: 'cancel purchase',
        share_listing_facebook: 'share listing on facebook',
        share_listing_twitter: 'share listing on twitter',
        share_listing_tumblr: 'share listing on tumblr',
      )
    )

    # Application event logging

    config.event_logging = OpenStruct.new(
      use_syslog: true,
      log_facility: Syslog::LOG_USER,
      log_level: Syslog::LOG_DEBUG,
      log_name: 'brooklyn-events',
      log_file: File.join('log', "#{Rails.env}.log")
    )

    # Homepage

    config.home = OpenStruct.new(
      trending: OpenStruct.new(
        active_snapshots: 3,
        window: 1,  #days
        per_page: 36,
        listing_count: 36 * 6 # a multiple of per_page just because
      ),
      featured: OpenStruct.new(
        active_snapshots: 3,
        window: 2,  #days
        per_page: 36,
        listing_count: 36 * 6, # a multiple of per_page just because
        batch_size: 100 # pyramid request batch size
      ),
      collection_carousel: OpenStruct.new(
        window: 24.hours, # seconds before now defining the oldest follows to consider
        limit: 50,        # total number of collections to consider
        sample_size: 12,  # total number to cycle through (should be a multiple of group_size)
        group_size: 3,    # number on screen at one time
        min_listings: 5   # minimum number of listings a collection must have to be considered
      )
    )

    # Social networks

    config.networks = OpenStruct.new(
      active: [:facebook, :twitter, :tumblr, :instagram],
      registerable: [:facebook, :twitter],
      shareable: [:facebook, :twitter, :tumblr, :pinterest],
      autoshareable: [:facebook, :twitter],
      # add networks here that should be sync'd with mendocino instead of rubicon
      mendocino_syncable: [:facebook, :twitter],
      publish_signup_delay_secs: 30,
      hidden_for_users: [],

      facebook: OpenStruct.new(
        url: 'http://facebook.com/',
        app_id: '',
        app_secret: '',
        access_token: '',
        autoshare: [:user_followed, :listing_activated, :listing_sold, :listing_commented, :listing_liked, :offer_earned],
        timeline_autoshare: [:user_followed, :listing_activated, :listing_sold, :listing_liked, :listing_commented, :offer_earned],
        invite: OpenStruct.new(
          picture: 'http://copious.com/assets/layout/copious_logo_v2.png',
          link: "http://www.copious.com/",
          type: 'link'
        ),
        invite_with_credit: OpenStruct.new(
          picture: 'http://copious.com/assets/layout/copious_logo_v2.png',
          link: "http://www.copious.com/",
          type: 'link'
        ),
        notification: OpenStruct.new(
          per: 15, # batch size when processing notifications to fb
          listing_title_length: 40,
          follow: OpenStruct.new(
            ref: 'notif_friend_follow'
          ),
          like: OpenStruct.new(
            ref: 'notif_friend_love'
          ),
          comment: OpenStruct.new(
            ref: 'notif_friend_comment'
          ),
          announce: OpenStruct.new(
            ref: 'notif_admin_announce'
          ),
          price_alert: OpenStruct.new(
            ref_prefix: 'notif_price_alert',
            interacted_with_listing_choices: 50,
            random_trending_window: 7, # days
            random_trending_listing_choices: 50,
            title_max_length: 40 # characters
          ),
          # See app/controllers/facebook/canvas_controller.rb.
          # This regex parses the request referer after a redirect
          # to us from Facebook via the Canvas app.
          canvas_redirect_regex: "facebook.com\/copious\/{1,2}(\\S+)$"
        ),
        # picture and link are defaults which are overwritten by the feed posting code
        signup: OpenStruct.new(
          picture: 'http://copious.com/assets/layout/copious_logo_v2.png',
          link: "http://www.copious.com/"
        ),
        share_listing_activated: OpenStruct.new(
          picture: 'http://copious.com/assets/layout/copious_logo_v2.png',
          link: "http://www.copious.com/"
        ),
        share_listing_liked: OpenStruct.new(
          picture: 'http://copious.com/assets/layout/copious_logo_v2.png',
          link: "http://www.copious.com/"
        ),
        share_listing_commented: OpenStruct.new(
          picture: 'http://copious.com/assets/layout/copious_logo_v2.png',
          link: "http://www.copious.com/"
        ),
        share_user_followed: OpenStruct.new(
          picture: 'http://copious.com/assets/layout/copious_logo_v2.png',
          link: "http://www.copious.com/"
        ),
        photo_url: "http://graph.facebook.com/%{fbid}/picture",
        permissions: OpenStruct.new(
          # "friends_interests, friends_likes" required for future information gathering
          # "publish_actions" required for Custom Open Graph access.
          required: [:email, :publish_actions, :user_birthday, :user_likes,
            :user_location, :user_status, :user_photos, :friends_photos],
          optional: []
        ),
        og: OpenStruct.new(
          admins: '',
          post_delay_secs: 10,
          post: OpenStruct.new(
            image_count: 3
          ),
          sell: OpenStruct.new(
            image_count: 3
          ),
        ),
        follow_rank: OpenStruct.new(
          shared_connections: OpenStruct.new(
            coefficient: 0.35
          ),
          network_affinity: OpenStruct.new(
            coefficient: 0.65
          ),
          photo_tags: OpenStruct.new(
            minimum: 2,
            coefficient: 0.38
          ),
          photo_annotations: OpenStruct.new(
            window: 90, # days
            coefficient: 0.31
          ),
          status_annotations: OpenStruct.new(
            window: 30, # days
            coefficient: 0.31
          )
        ),
        u2u_invites: OpenStruct.new(
          # do not allow the viewer to invite users he already send U2U invite requests to within this period of time
          exclude_invited_since: 1.day.ago
        )
      ),

      twitter: OpenStruct.new(
        url: 'http://twitter.com/',
        corporate: 'shopcopious',
        app_id: '',
        app_secret: '',
        autoshare: [:listing_activated, :listing_commented, :listing_liked, :user_followed],
        never_autoshare: true
      ),

      tumblr: OpenStruct.new(
        url: 'http://tumblr.com/',
        app_id: '',
        app_secret: ''
      ),

      # Managed by copiousdev instagram account.  Secure (dev) app managed
      # by copiousdev2 account due to limit of 5 apps per account
      instagram: OpenStruct.new(
        url: 'http://instagr.am/',
        app_id: '',
        app_secret: '',
        app_id_secure: '',
        app_secret_secure: ''
      ),
    )

    # Security

    config.security = OpenStruct.new(
      passwords: OpenStruct.new(
        pepper: '',
        cost: 10
      )
    )

    # Recaptcha

    config.recaptcha = OpenStruct.new(
      key: '',
      secret: ''
    )
    # Sync
    config.sync = OpenStruct.new(
      listings: OpenStruct.new(
        active_sources: [],

        e_drop_off: OpenStruct.new(
          shipping: 9.00,
          pricing_version: 1,
          url: 'http://shopedo.venturality.com/Product/CsvFeed',
          seller_slug: 'robert-zuber',
          categories: OpenStruct.new(
            handbags: [:clutches, :wallets, :handbags],
            clothing: [:shorts, :casual, :dressy, :skirts, :sweaters, :jackets],
            jewelry: [:bracelets, :necklaces, :rings],
            accessories: [:misc]
          )
        ),

        ajm: OpenStruct.new(
          pricing_version: 1,
          max_tag_length: 64,
          provider: :channel_advisor,
          bucket: 'utahstreetlabs.com-ftp',
          pattern: 'ajmfashions/(\w+)\.txt',
          seller_slug: 'ajm-fashions',
          categories: OpenStruct.new(
            accessories: [2993, 3003, 52382, "Womens Accessories"],
            clothing: [11483, 11484, 11525, 11532, 11555, 11555, 15687, 15689, 15746, 50990, 53159, 57989, 57990, 57991,
              63853, 63854, 63855, 63860, 63861, 63862, 63863, 63864, 63865, 63866, 63867, 63868, 63869, 108898, 155183,
              155203, 163868, 169001, "Womens Sweaters", "Womens Tops", "Womens Dresses", "Womens Pants",
              "Womens Shorts", "Womens Jeans", "Womens Skirts", "Mens Jeans", "Mens Shirts", "Womens Outerwear/Coats",
              "Mens Sweaters", "Womens Blazers/Jackets", "Womens Intimates", "Mens Pants", "Womens Swimwear",
              "Mens Shorts", "Mens Outerwear", "Womens Outerwear"],
            handbags: [63852, "Handbags - Large/Tote", "Handbags - Small"],
            health_beauty: ["Beauty"],
            jewelry: [50638, 50649, 67681, 92727, 111560, 164321, 164334, 164345, "Jewelry"],
            shoes: [45333, 53557, 63850, 63889, "Womens Boots", "Womens Shoes - w/ box", "Mens Shoes",
              "Womens Shoes - w/o box"]
          )
        )
      ),
    )

    # Credits feature

    config.credits = OpenStruct.new(
      minimum_real_charge: 1.00,
      min_days_halfway_reminder: 4,
      default: OpenStruct.new(
        duration: 14.days
      ),
      apply: OpenStruct.new(
        suggest_max_applicable: true,
        retries: 1
      ),
      inviter: OpenStruct.new(
        amount: 5,
        duration: 14.days,
        max_per_invitee: 25
      ),
      invitee: OpenStruct.new(
        amount: 10,
        duration: 14.days,
        min_followers: 26
      )
    )

    # Invites feature

    config.invites = OpenStruct.new(
      email: OpenStruct.new(max_recipients: 100),
      facebook: OpenStruct.new(max_recipients: 12),
      max_creditable_acceptances: 40
    )

    # Offers feature

    config.offers = OpenStruct.new(
      min_followers: 25,
      # uuids for each offer whose landing page gets custom body classes - each uuid maps to a list of class names
      custom_body_classes: {
        'boo'         => %w(boo_landing),
        'festivus'    => %w(cyber_monday),
        'secret-seller' => %w(secret_seller),
      },
      # uuids for each offer whose landing page gets a full screen background
      full_screen_background: [
        'boo',
        'festivus'
      ]
    )

    # Custom order job scheduling

    config.orders = OpenStruct.new(
      review_period_duration: 2.days,
      confirmed_unshipped_cancellation_buffer: 15.days,
      delivery_confirmation_period_duration: 7.days,
      delivery_non_confirmation_followup_period_duration: 4.days,
      shipping_address_change_window: 1.hour,
      # remind seller of unshipped order this amount of time before the handling period ends
      handling_period_full_reminder_window: 2.days,
      # if the handling period is this or shorter, use the abbreviated reminder window instead
      handling_period_reminder_abbrev_threshold: 4.days,
      # if the handling period is abbreviated, remind seller of unshipped order this amount of time before the
      # handling period ends instead
      handling_period_abbrev_reminder_window: 1.day,
      # if the handling period is this or shorter, don't remind the seller of unshipped order at all
      handling_period_reminder_none_threshold: 1.day,
    )

    config.shipments = OpenStruct.new(
      # the amount of time we wait between successive shipment status checks
      shipment_status_check_delay: 6.hours,
      # the amount of time we wait before the initial delivery status check
      delivery_status_check_delay: 12.hours,
      # the amount of time we wait between successive delivery status checks
      delivery_status_recheck_delay: 6.hours
    )

    # Tag-related features

    config.tags = OpenStruct.new(
      cards: OpenStruct.new(
        # the default number of listing photos to show on each tag card
        profile_listing_count: 9
      ),
      likes: OpenStruct.new(
        # the distance into the past to show stories about a tag when a tag is liked
        story_window: 72.hours
      )
    )

    config.interests = OpenStruct.new(
      signup: OpenStruct.new(
        options: 12,  # the number to show on the signup page
        required: 5   # the number the user must select before moving to the next step in the signup flow
      ),
      cards: OpenStruct.new(
        # the default number of listing photos to show on each interest card
        signup_listing_count: 6,
        # the default number of users to display per interest.
        suggested_person_count: 2
      )
    )

    # User-related features

    config.users = OpenStruct.new(
      # settings for the connection digest email
      connection_digest: OpenStruct.new(
        # try to find this many listings
        max_listing_count: 10,
        # don't send if we can't find at least this many listings
        min_listing_count: 6
      ),
      signup: OpenStruct.new(
        # if any curated users are to be auto-followed during signup, then fill in this array with the selected
        # users' email addresses
        curated: [],
        # if no users are curated, then this many randomly chosen users will be displayed on /signup/users
        random: 10,
      ),
      recent_listings: OpenStruct.new(
        # the number of recent listings to cache. since there are 3 recent listing queues, the total number per user
        # is 3 times this number.
        queue_size: 6
      ),
      stash: OpenStruct.new(
        expire_secs: 3600,
        # How often to sync user profile data for an active user (every 15 minutes)
        sync_update_profile_secs: 900,
        feed_refresh_expire_secs: 3600
      ),
      profile: OpenStruct.new(
        per_page: 30
      ),
      notifications: OpenStruct.new(
        per_page: 30,
        # Automatically clear notifications after they have been viewed for this amount of time or longer
        autoclear_viewed_period: 10.days
      ),
      feedback: OpenStruct.new(
        per_page: 30
      ),
      card: OpenStruct.new(
        listing_count: 12,
        blank_slots: [6, 7, 10, 11]
      ),
      interests: OpenStruct.new(
        minimum_needed_to_build_feed: 5,
        max_interest_likes: 1000
      ),
      scheduled_follows: {
        # follower slug   => the number of seconds in the future to create the follow
      }
    )

    # Follow-related features

    config.follows = OpenStruct.new(
      # the distance into the past to show stories about a tag when a tag is liked
      new_story_window: 72.hours
    )

    config.collections = OpenStruct.new(
      # the distance into the past to show stories about a tag when a tag is liked
      max_per_user: 200,
      card: OpenStruct.new(
        listing_count: 5
      ),
      items_per_page: 30,
      success_modal: OpenStruct.new(
        listing_count: 4
      ),
      create: OpenStruct.new(
        listings_modal: OpenStruct.new(
          listing_count: 20
        ),
        success_modal: OpenStruct.new(
          listing_count: 4
        )
      ),
      autofollow: OpenStruct.new(
        per_interest: 4
      )
    )

    # Feed-related features

    config.feed = OpenStruct.new(
      defaults: OpenStruct.new(
        offset: 0,
        limit: 36
      ),
      card: OpenStruct.new(
        # types of stories that should be included in the card feed
        story_types: [:listing_activated, :listing_liked, :listing_commented, :listing_sold, :listing_shared,
                      :tag_liked],
        invite: OpenStruct.new(
          position: 8
        ),
        follow: OpenStruct.new(
          position: 1
        ),
        facebook_facepile_invite: OpenStruct.new(
          count: 16
        ),
        promotion: OpenStruct.new(
          position: 5,
          active: [:secret_seller, :ios],
          secret_seller: OpenStruct.new(
            link: lambda { Brooklyn::Application.routes.url_helpers.new_secret_seller_item_path },
            image: 'landing/secret-seller/Secret_Seller_card.jpg'
          ),
          ios: OpenStruct.new(
            # looks like Brooklyn::Application.routes.url_helpers.new_secret_seller_item_path
            # doesn't work, so hardcode
            link: 'https://itunes.apple.com/us/app/copious/id574056622?mt=8',
            image: 'promotions/ios.jpg',
            view_event: 'mobile_card view',
            click_event: 'mobile-card-click'
          )
        )
      )
    )

    config.cards = OpenStruct.new(
      comments: 10 # number of comments to display on the back of a card.
    )

    config.connect = OpenStruct.new(
      who_to_follow: OpenStruct.new(
        per_page: 12
      )
    )

    # Typekit support

    config.typekit = OpenStruct.new(
      token: ""
    )

    # Optimizely support

    config.optimizely = OpenStruct.new(
      token: ""
    )

    config.js_sdk = OpenStruct.new(
      host: 'localhost:3000'
    )

    config.bookmarklet = OpenStruct.new(
      # Target of window.open for bookmarklet popup
      domain: 'copious.com',
      # Host that serves bookmarklet source
      host: 'bookmarklet.copious.com'
    )

    # default settings for http client requests
    config.http = OpenStruct.new(
      user_agent: 'Copious/1.0 (http://copious.com)',
      open_timeout: 2, # seconds
      read_timeout: 5  # seconds
    )

    config.listing_sources = OpenStruct.new(
      image_choice_count: 5,
      image_minimum_width: 90,
      image_minimum_height: 90,
      image_minimum_area: 8100, # pixels (~90x90),
      image_minimum_size: 8.kilobytes,
      scraper: OpenStruct.new(
        user_agent: config.http.user_agent,
        open_timeout: config.http.open_timeout,
        read_timeout: config.http.read_timeout
      )
    )

    config.flash = OpenStruct.new(
      duration: 5000
    )

    config.hot_or_not = OpenStruct.new(
      likes_needed_for_completion: 10, # user must like this many listings to complete
      registered_since: 1.day.ago,     # require is user to go through the process if he registered since this time
      likes_needed_for_custom: 5,      # user must like this many listings to get customized results
      trending: OpenStruct.new(
        window: 1,                     # consider trending listings within this many days before now
        limit: 36                      # choose suggestions from this many trending listings
      )
    )
  end
end
