module LoginHelper
  def autologin_modal
    unless logged_in?
      javascript 'facebook'
      javascript 'gatekeeper' if autologin_permitted?
    end
    bootstrap_modal(:logging_in, nil, show_save: false, show_close: false, show_footer: false, show_header: false,
                    never_close: true, class: 'logging-in-modal') do
      t("shared.modal.logging_in_html")
    end
  end

  def waiting_modal
    bootstrap_modal(:waiting, nil, show_save: false, show_close: false, show_footer: false, show_header: false,
                    never_close: true, class: 'waiting-modal') do
      out = []
      out << t("shared.modal.waiting_html")
      out << dot_spinner
      safe_join(out)
    end
  end

  def facebook_auth_params(options = {})
    auth_params = {}
    auth_params[:seller_signup] = options[:seller_signup] if options[:seller_signup]
    auth_params[:scope] = options[:scope] if options[:scope]
    auth_params[:d] = options[:d] || request.fullpath
    # :'mobile-role' is used by the mobile client to transition control from a web view back
    # to native views.  Do not change without updating harpoon.
    params = {data: {action: "auth-facebook", mobile_role: "webview-complete",
                     primary: options.fetch(:primary, true)}}
    params[:data][:signup] = true if !!options[:signup]
    params[:data][:auth_url] = Network::Facebook.auth_callback_path(auth_params)
    params
  end

  def link_to_facebook_connect(options = {})
    label = options.fetch(:label, "Connect with Facebook")
    cl = options.fetch(:class, "button primary large facebook signup")
    link_text = options.fetch(:show_image, true) ? image_and_text("social_networks/loh-facebook-icon.png", label) : label
    link_to link_text, nilhref, facebook_auth_params(options).merge(class: cl)
  end

  def link_to_twitter_connect(options = {})
    label = options.fetch(:label, "Connect with Twitter")
    cl = "twitter signup #{options[:class]}"
    link_text = options.fetch(:show_image, true) ? image_and_text("social_networks/loh-twitter-icon.png", label) : label
    href = if options[:href].present?
      options[:href]
    else
      auth_options = {}
      if options[:seller_signup]
        auth_options[:seller_signup] = true
      else
        auth_options[:buyer_signup] = true
      end
      auth_path(:twitter, auth_options)
    end
    data = {action: 'auth-twitter'}
    data[:primary] = options.fetch(:primary, true)
    data[:signup] = true if !!options[:signup]
    link_to link_text, href, class: cl, data: data
  end

  def link_to_username_login(*args)
    options = args.extract_options!
    text = args.any? ? args.shift : 'log in with your username'
    path = @page_source && @page_source.match('bookmarklet') ? login_path(source: :bookmarklet) : login_path
    data = {action: 'login_with_username'}
    data[:primary] = options.fetch(:primary, true)
    link_to(text, path, data: data)
  end

  def signup_modal(options = {})
    twitter_url_options = {network: :twitter}
    twitter_url_options[:d] = params[:d] if params[:d].present?
    # Set [data-source=forced] for MP tracking when open on load. Takes on source of event target if triggered by user.
    bootstrap_modal(:signup, nil, show_save: false, show_close: false, show_footer: false, show_header: false,
                   hidden: true, data: {source: 'forced'}) do
      content_tag(:div, class: 'container') do
        out = []
        out << content_tag(:div, class: 'section top-piece') do
          out2 = []
          out2 << content_tag(:h1, class: 'hidden-phone hero styled-header') do
            t('signup_modal.top.desktop_html')
          end
          out2 << content_tag(:h1, class: 'hidden-desktop kill-margin-top') do
            t('signup_modal.top.phone_html')
          end
          out2 << content_tag(:div, class: 'alert', data: {role: 'alert'},
                              style: (options[:show_alert] ? '' : 'display:none;')) do
            raw(flash[:alert])
          end
          safe_join(out2)
        end
        out << content_tag(:div, class: 'row') do
          out2 = []
          out2 << content_tag(:div, class: 'section') do
            out3 = []
            out3 << content_tag(:div, class: 'sns-connect') do
              out4 = []
              out4 << link_to_facebook_connect(label: t('signup_modal.button.facebook'), signup: true, primary: false,
                                               class: 'signup button facebook full-width')
              out4 << link_to_twitter_connect(label: t('signup_modal.button.twitter'), signup: true, primary: false,
                                              class: 'signup button full-width',
                                              href: auth_prepare_path(twitter_url_options))
              out4 << tag(:br)
              safe_join(out4)
            end
            out3 << content_tag(:div, class: 'remember-me') do
              out4 = []
              out4 << check_box_tag(:remember_me, '1', true, class: 'margin-top', id: 'network-login-remember-me')
              out4 << label_tag(:remember_me, t('signup_modal.remember_me'), class: 'checkbox margin-top weak')
              safe_join(out4)
            end
            safe_join(out3)
          end
          out2 << content_tag(:div, class: 'bottom-piece') do
            content_tag(:p, class: 'already-registered') do
              t('signup_modal.bottom.login_html',
                login_link: link_to_username_login(t('signup_modal.bottom.login_link'), primary: false))
            end
          end
          safe_join(out2)
        end
        safe_join(out)
      end
    end
  end

  def sticky_logged_out_header(options = {})
    classes = 'home-user-container logged-out-header sticky-header'
    content_tag(:div, class: classes) do
      content_tag(:div, class: 'home-header') do
        out = []
        out << content_tag(:h1, t('shared.sticky_headers.logged_out.title'), class: 'hero')
        out << content_tag(:div, class: 'connect-container') do
          out2 = []
          out2 << link_to_facebook_connect(class: 'signup button xlarge facebook', primary: false)
          unless feature_enabled?('signup.entry_point.fb_oauth_dialog') &&
                 ab_test(:signup_entry_point).in?(([:fb_oauth_dialog_1, :fb_oauth_dialog_2]))
            out2 << link_to_twitter_connect(class: 'button xlarge twitter')
          end
          safe_join(out2)
        end
        safe_join(out)
      end
    end
  end

  def logged_out_footer
    classes = 'logged-out-footer'
    content_tag(:div, class: classes, data: {source: 'footer'}) do
      out = []
      out << link_to('/signup', class: 'signup-link') do
        button_tag(t('shared.welcome_footers.home.logged_out.signup_button'),
                   class: 'signup btn xlarge margin-bottom', type: 'button',
                   data: {always_protected: true})
      end
      out << content_tag(:div, class: 'login-container') do
        content_tag(:span, class: 'already-registered') do
          out2 = []
          out2 << t('shared.welcome_footers.home.logged_out.connect1')
          out2 << link_to(t('shared.welcome_footers.home.logged_out.connect2'), '/login',
                          data: {action: 'auth'})
          out2 << '.'
          safe_join(out2)
        end
      end
      safe_join(out)
    end
  end
end
