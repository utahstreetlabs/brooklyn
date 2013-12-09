Brooklyn::Application.routes.draw do
  root :to => 'home#index'

  resource :dashboard, :controller => 'dashboard', :only => :show do
    get :bought
    get :inactive
    get :draft
    get :suspended
    get :for_sale
    get :sold
    get :sandbox
    resources :orders, controller: 'dashboard/orders', only: [] do
      post :private
      post :public
      post :delivered
      post :not_delivered
    end
    resources :transactions, controller: 'dashboard/transactions', only: [:index]
  end

  namespace :dashboard do
    namespace :invites do
      resources :suggestions, only: [:index, :destroy]
      resources :profiles, only: [:update]
    end
  end

  resources :notifications, only: [:index, :destroy]

  resources :follow_suggestions, only: [:index, :destroy]

  namespace :invites do
    resources :facebook_u2u, only: [:create]
    resources :facebook_suggestions, only: [:index]
  end
  resources :invites, only: [:show]

  resources :offers, :only => [:show] do
    get :accept, controller: :offers
  end

  namespace 'facebook' do
    resource :friends, only: [] do
      get :registered
    end
    resource :connection, only: [:show]
    # looks like most of the time FB sends a POST for the canvas page, but I also see GET requests from user agent
    # "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)" which looks like a scraper of
    # some sort, so support both methods
    resource :canvas, only: :show
    post 'canvas' => 'canvas#show'
  end

  match '/auth/prepare' => 'auth#prepare'
  match '/auth/:network/setup' => 'auth#setup'
  match '/auth/:network/callback' => 'auth#callback'
  # XXX weird block syntax here -- for some reason actiondispatch 3.1.x doesn't like
  # "redirect do |params,req|" even though docs say that should work.  Update in the future.
  match '/auth/:network/welcome' => redirect { |params, req|
    r = "/auth/#{params[:network]}?state=w"
    r << "&#{req.query_string}" if req.query_string
    r
  }
  match '/auth/failure' => 'auth#failure'

  resources :email_accounts, :only => [:new, :create, :show] do
    resources :contacts, :controller => 'email_accounts/contacts', :only => :index
  end

  resource :profile, controller: :profile, only: [:new, :create] do
    resource :networks do
      resource :connected, controller: :'profile/networks/connected', only: [:show]
    end
  end

  namespace :settings do
    resource :profile, controller: 'profile', only: [:show, :update] do
      resource :photo, only: [:create, :update]
    end
    resource :password, controller: 'password', only: [:show, :update]
    resource :email, controller: 'email', only: [:show, :update] do
      collection do
        put :update_prefs
      end
    end
    namespace :feature do
      put :update_prefs, format: :json
    end
    resources :networks, controller: 'networks', only: [:index, :update, :destroy] do
      collection do
        put 'autoshare/:network/:event', action: :allow_autoshare, as: :autoshare
        put :never_autoshare
        scope 'facebook', controller: 'networks/facebook' do
          put :disable_timeline, format: :json
          get :timeline_permission, format: :json
        end
      end
    end
    resources :shipping_addresses, controller: 'shipping_addresses', only: [:index, :create, :update, :destroy] do
      resource :default, controller: 'shipping_addresses/default', only: [:update]
    end
    resource :privacy, controller: 'privacy', only: [:show, :update]
    namespace :seller do
      resource :identity, controller: 'identity', only: [:show, :update]
      resources :accounts, controller: 'accounts', except: [:show, :edit, :update] do
        post :default
      end
      namespace :accounts do
        resources :paypal, controller: 'paypal', only: [:edit, :update]
      end
    end
    resource :credits, controller: 'credits', only: [:show]
    resource :invites, controller: 'invites', only: [:show]
  end

  resources :profiles, only: [:show], as: :public_profile do
    member do
      get 'for-sale' => 'profiles#for_sale', as: :for_sale
      get 'loved' => 'profiles#liked', as: :liked
      get 'liked' => redirect("/profiles/%{id}/loved")
      get :followers
    end
    resource :following, only: [] do
      get :collections, controller: 'profiles/following'
      get :people, controller: 'profiles/following'
    end
    scope :module => 'profiles', controller: :follow do
      collection do
        get :typeahead
      end
      get :follow
      put :follow
      delete :unfollow
      put :block
      delete :unblock
    end
    resources :collections, controller: 'profiles/collections', only: [:index, :show]
    resources :followees, controller: 'profiles/followees', only: [:update, :destroy]
    resources :feedback, controller: 'profiles/feedback', only: [] do
      collection do
        get :selling
        get :buying
      end
    end
  end

  resources :collections, only: [:create, :update, :destroy] do
    resources :listings, only: [:create, :destroy], controller: 'collections/listings'
    scope module: 'collections', controller: :follow do
      put :follow
      delete :unfollow
    end
    member do
      post :populate
    end
  end

  resources :listings, only: [:new, :create, :edit, :update, :show, :destroy] do
    collection do
      get '' => redirect { |params, req| "/for-sale?#{req.query_string}"}
      get '/for/:category' => redirect { |params, req| "/for-sale/#{params[:category]}?#{req.query_string}" }
    end
    resources :collections, only: [:create], controller: 'listings/collections' do
      collection do
        put '' => 'listings/collections#update'
        get :save_modal, controller: 'listings/collections'
      end
      resources :wants, only: [:create, :update], controller: 'listings/collections/wants' do
        collection do
          get :complete
        end
      end
    end
    resource :hotness, only: [:create, :destroy], controller: 'listings/hotness'
    resource :features, only: [:update], controller: 'listings/features' do
      get :feature_modal
    end
    member do
      get :setup
      post :draft
      post :complete
      post :activate
      get :invoice
      get :like
      put :like
      delete :unlike
      put :flag
      post :ship
      post :deliver
      post :not_delivered
      post :finalize
      post :change_shipping
      get 'share/:network(/:photo_id)' => 'listings#share', as: :share
      post :feature
      get :sandbox
      post :private
      post :public
      get :external
    end
    resources :photos, :only => [:new, :create, :update, :destroy], :controller => 'listings/photos' do
      post :reorder
      post :make_primary
    end
    resource :purchase, :only => [:show, :destroy], :controller => 'listings/purchase' do
      get :shipping
      post :create_shipping_address
      post :ship_to
      get :payment
      post :sell
      put :credit
    end
    resource :return_address, :only => [:create, :update], :controller => 'listings/return_address'
    resources :comments, only: [:create, :destroy], controller: 'listings/comments' do
      post :resend_email, format: :json
      resources :flags, only: [:create], controller: 'listings/comments/flags'
      delete :unflag, controller: 'listings/comments/flags', format: :json
      resources :replies, only: [:create, :destroy], controller: 'listings/comments/replies' do
        post :resend_email, format: :json
        resources :flags, only: [:create], controller: 'listings/comments/replies/flags'
        delete :unflag, controller: 'listings/comments/replies/flags', format: :json
      end
    end
    resources :instagram, only: [:index, :update], controller: 'listings/instagram_photos'
    resource :shipping_label, only: [:create, :show], controller: 'listings/shipping_label'
    resources :offers, only: [:create], controller: 'listings/offers'
    resource :bookmarklet, only: [], controller: 'listings/external/bookmarklet' do
      resources :collections, only: :index, controller: 'listings/external/bookmarklet/collections'
      member do
        get :complete
      end
    end
    resource :modal, only: :show, controller: 'listings/modal' do
      resource :like, only: [:update, :destroy], controller: 'listings/modal/like'
      resources :comments, only: :create, controller: 'listings/modal/comments'
      resource :top, only: :show, controller: 'listings/modal/top'
    end
  end

  resources :listing_sources, only: [:create]
  get 'listings/from/bookmarklet' => 'listings/bookmarklet#show'
  match 'listings/from/:uuid/new', to: 'listings/external#new', as: :new_external_listing
  post 'listings/from/:uuid/create' => 'listings/external#create', as: :external_listings

  resource :trending, only: :show, controller: 'trending'

  namespace :feed do
    resources :listings, only: [:index, :destroy] do
      resources :comments, only: :create, controller: 'listings/comments'
      collection do
        resource :new, only: [] do
          get :count, controller: 'listings'
        end
        put :refresh_timestamp, controller: 'listings'
      end
    end
    resources :users, controller: 'users', only: [] do
      put :follow
      delete :unfollow
    end
    namespace :facebook_facepile_invites do
      resources :requests, only: :create
    end
  end

  namespace :notifications do
    resources :unviewed do
      collection do
        get :count
      end
    end
  end

  scope 'for-sale' do
    get 'new-arrivals(/:category(/*path_tags))' => 'search_browse#new_arrivals', as: :new_arrivals_for_sale
    get '(:category)(/*path_tags)' => 'search_browse#browse', as: :browse_for_sale
  end

  resources :orders, :only => [] do
    post :ship
    post :complete
    post :public
    post :private
    post :settle, on: :collection
  end

  resources :categories, :only => :none do
    collection do
      get :autocomplete, :format => :json
    end
  end

  resources :tags, :only => :none do
    put :like
    delete :unlike
    collection do
      get :autocomplete, :format => :json
      get :typeahead
    end
  end

  get 'signup' => 'home#signup'
  namespace :home do
    delete 'invite-bar' => 'invite_bar#destroy', format: :json, as: :invite_bar
  end

  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  get 'logout' => 'sessions#destroy'

  namespace :signup do
    get :onboard # part of legacy buyer flow
    namespace :invites do
      resources :facebook, only: [:index, :create], controller: :facebook do
        get :search, on: :collection
      end
      resources :shares, only: [:index, :create, :show]
      resources :email, only: [:index, :create], controller: :email
    end
    namespace :buyer do
      resource :profile, only: [:new, :create]
      resources :tags, only: [:index] do
        put :like
        delete :unlike
      end
      resources :people, only: [:index] do
        collection { post :complete }
      end
      resources :friends, only: [:index] do
        collection do
          get :follow_suggestions
          post :complete
        end
      end
      resources :interests, only: [:index] do
        put :like
        delete :unlike
        collection do
          post :complete
          resource :feed_build, only: [:create]
        end
      end
    end
  end

  namespace :connect do
    resources :who_to_follow, controller: 'who_to_follow', only: :index
    namespace :invites do
      resources :facebook, only: :create, controller: :facebook do
        get :search, on: :collection
      end
      resources :email, only: :create, controller: :email
    end
    resources :invites, only: :index
  end

  resources :password_resets, :only => [:new, :create, :show, :update]

  namespace :secret_seller do
    resources :items, only: [:new, :create] do
      get :thanks, on: :collection
    end
  end

  namespace :admin do
    resource :dashboard, :controller => 'dashboard', :only => :show
    resources :feature_flags, only: [:index] do
      resource :user, only: [:create, :destroy], controller: 'feature_flags/user'
      resource :admin, only: [:create, :destroy], controller: 'feature_flags/admin'
    end
    resources :orders, :only => [:index, :show] do
      collection do
        get :handling_expired
        get :cancelled
      end
      member do
        post :confirm
        post :complete
        post :deliver
        post :settle
        post :ship
        delete :cancel
      end
      resources :annotations, only: [:create, :destroy]
      resource :shipment, controller: 'orders/shipments', only: [:update]
      resource :shipping_label, controller: 'orders/shipping_label', only: [:show]
    end
    resources :cancelled_orders, :only => [] do
      resources :annotations, only: [:create, :destroy]
    end
    namespace :users do
      resources :autofollows, controller: 'autofollows', only: [:index]
    end
    resources :users do
      collection do
        get :typeahead
      end
      member do
        post :deactivate
        post :reactivate
      end
      resources :credits, controller: 'users/credits', only: [:create]
      resource :web_site, controller: 'users/web_site', only: [:update]
      resource :listing_access, controller: 'users/listing_access', only: [:update]
      resources :orders, controller: 'users/orders', only: [:index, :show]
      resources :listings, controller: 'users/listings', only: [:index, :show]
      resources :collections, controller: 'users/collections', only: [:index]
      resources :suggestions, controller: 'users/suggestions', only: [] do
        post :set, on: :collection
      end
      resources :hot_or_not, controller: 'users/hot_or_not', only: [:index]
      resource :autofollows, controller: 'users/autofollows', only: [] do
        collection do
          post :add
          post :remove
          post :reorder
        end
      end
      resource :superuser, controller: 'users/superuser', only: [:update, :destroy]
      resource :admin, controller: 'users/admin', only: [:update, :destroy]
      resources :annotations, only: [:create, :destroy]
      resources :follow_email, controller: 'users/follow_emails', only: :create
    end
    resources :categories, :only => [:index, :show] do
      resources :featured, controller: 'categories/featured', only: [:destroy] do
        post :reorder, on: :member
      end
    end
    resources :feature_lists, :only => [:index, :show] do
      resources :featured, controller: 'feature_lists/featured', only: [:destroy] do
        post :reorder, on: :member
      end
    end
    namespace :listings do
      resources :bullpen, controller: 'bullpen', only: [:index] do
        member do
          post :approve
          post :disapprove
        end
      end
    end
    resources :collections, :only => [:index, :show, :edit, :update, :destroy] do
      resources :autofollows, controller: 'collections/autofollows', only: [] do
        post :set, on: :collection
      end
    end
    resources :listings, :only => [:index, :show, :edit, :update] do
      member do
        post :activate
        post :deactivate
        post :reactivate
        post :suspend
        post :sell
        post :cancel
        post :approve
        post :disapprove
        post :feature_for_category
        post :feature_for_tags
        post :feature_on_feature_lists
      end
      resources :love_email, controller: 'listings/love_emails', only: :create
    end
    resources :tags do
      delete :destroy_all, on: :collection
      post :merge, :promote, on: :member
      resources :featured, controller: 'tags/featured', only: [:destroy] do
        post :reorder, on: :member
      end
    end
    namespace :facebook do
      resources :announcements, controller: 'announcements', only: [:index, :create]
      resources :price_alerts, controller: 'price_alerts', only: [:index, :create]
    end
    resources :offers, only: [:index, :new, :create, :edit, :update]
    match 'vanity(/:action(/:id))', :to => 'vanity', :as => :vanity
    resources :interests do
      collection do
        post :add_all_to_onboarding
        post :remove_all_from_onboarding
        delete :destroy_all
      end
      resources :collection, controller: 'interests/collections', only: [:destroy]
      resources :users, controller: 'interests/users', only: [:destroy] do
        post :reorder, on: :member
      end
    end
    namespace :onboarding do
      resources :interests, only: [:index, :destroy] do
        post :reorder, on: :member
      end
    end
    namespace :payments do
      resources :paypal, only: [:index] do
        post :pay_all, on: :collection
      end
    end
    namespace :scores do
      resources :interests, only: [:index]
    end
  end

  namespace :callbacks do
    get :shared
    get :connected
    namespace :facebook do
      get :connected
    end
  end

  namespace :api, path: 'v1', defaults: {format: :json} do
    resources :categories, :only => :index
    resources :orders, :only => [:index, :show] do
      resources :shipment, :only => [:index, :create], :controller => 'orders/shipments'
    end
    resources :listings, :only => [:index, :show, :create, :update, :destroy] do
      collection do
        get :count
        resources :active, :only => :index, :controller => 'listings/active' do
          get :count, on: :collection
        end
      end
      member do
        post :activate
      end
      resources :photos, :only => [:index, :create, :update, :destroy], :controller => 'listings/photos' do
        collection do
          put :order
          get :count
          resources :position, controller: 'listings/photos/position', only: [:show, :update, :destroy]
        end
      end
    end

    namespace :geckoboard do
      resource :users, :only => :none do
        collection do
          get :count
          get :states
          get :registrations
        end
      end
    end
  end

  namespace :oauth do
    post 'token', to: proc { |env| OAuth::TokenEndpoint.new.call(env) }
  end

  namespace :info do
    resource :extras, only: :show
    get ':action'
  end

  get 'buyers/:template' => 'buyers#show', as: :buyers_show
  get 'sellers/:template' => 'sellers#show', as: :sellers_show

  namespace :errors do
    resource :javascript, :only => :create
  end

  resource :sandbox, :controller => 'sandbox', :only => [:show] do
    get :styleguide
    get :connect
  end

  resource :track, :only => [:show], controller: :tracking

  get ':template', :to => 'root#show', as: :root_show
  # work around rails 3.0.1 bug:
  # http://techoctave.com/c7/posts/36-rails-3-0-rescue-from-routing-error-solution
  # https://rails.lighthouseapp.com/projects/8994/tickets/4444-can-no-longer-rescue_from-actioncontrollerroutingerror
  # remove once we upgrade to 3.2 and can fix this in a different way:
  # https://github.com/jorlhuda/exceptron
  match '*path', :to => 'home#not_found'
end
