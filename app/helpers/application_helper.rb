# encoding: utf-8
module ApplicationHelper
  def title(text)
    content_for(:title) { text }
  end

  def doc_header(&block)
    content_for(:doc_header, &block)
  end

  # If set, adds the configured prefix to the <head> tag.  Used
  # by Facebook for defining Open Graph objects.
  # For more information, see http://developers.facebook.com/docs
  def fb_head_prefix
    content_for(:fb_head_prefix) do
      "og: http://ogp.me/ns# fb: http://ogp.me/ns/fb# copious: http://ogp.me/ns/fb/copious#"
    end
  end

  def head_tag(&block)
    attrs = {}
    attrs[:prefix] = content_for(:fb_head_prefix) if content_for?(:fb_head_prefix)
    content_tag :head, attrs, &block
  end

  def javascript(*args)
    content_for(:script_includes) { capture { javascript_include_tag(*args) } }
  end

  def external_javascript(*args)
    javascript(*args)
  end

  def base_stylesheet(options = {})
    stylesheet_link_tag('bootstrap_and_overrides', options) +
    stylesheet_link_tag('application', options)
  end

  def typekit_tags
    if feature_enabled?(:client, :typekit)
      out = javascript_include_tag "//use.typekit.com/#{Brooklyn::Application.config.typekit.token}.js".html_safe
      out << javascript_tag { "try {Typekit.load();} catch(e){}" }
      out
    end
  end

  def set_auth_policy(policy)
    @policy = policy
  end

  def gatekeeper_meta_tags(options = {})
    out = []
    unless logged_in?
      @policy ||= if feature_enabled?('auth.policy.immediate')
        :immediate
      elsif feature_enabled?('auth.policy.any')
        :any
      else
        :protected
      end
      out << tag(:meta, name: 'copious:auth-policy', content: @policy)
      # force-auth used as secondary auth policy by gatekeeper to force additional auth without affecting the default
      if options.has_key?(:force_auth)
        out << tag(:meta, name: 'copious:force-auth', content: options[:force_auth])
      end

      entry_point = if feature_enabled?('signup.entry_point.fb_oauth_dialog')
        ab_test(:signup_entry_point).in?([:fb_oauth_dialog_1, :fb_oauth_dialog_2]) ? 'fb' : 'modal'
      else
        'modal'
      end
      out << tag(:meta, name: 'copious:signup-entry-point', content: entry_point)
    end
    safe_join(out)
  end

  def stylesheet(*args)
    content_for(:stylesheet_includes) { capture { stylesheet_link_tag(*args) } }
  end

  def script(&b)
    content_for(:script, &b)
  end

  def prelude_script
    javascript_tag do
      tracking_config
    end
  end

  def handlebar_template(name, &block)
    content_for(:handlebar_templates) do
      content_tag :script, id: name, type: 'text/x-handlebars-template', &block
    end
  end

  def javascript_defaults(options = {})
    mp_identify
    scripts = ['application', 'bootstrap']
    scripts << 'login' if options[:login] == true
    prelude_script + jquery + javascript_include_tag(*scripts)
  end

  def jquery
    javascript_include_tag(
      '//ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js',
      '//ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js')
    # We need jquery 1.7.2 to fix an issue with endless scrolling in
    # ie8, but as of 4/13/12 we can't upgrade jquery-rails (which is where our
    # jquery artifacts come from in development) without upgrading to
    # rails 3.2. Until that happens, we're always pulling jquery
    # artifacts from the cdn, which may be inconvenient for those
    # developing on a plane. If you're on a plane, you can switch back
    # to the commented code: endless scroll will probably break in
    # IE8, but if you're on a plane and worrying about that you are insane.
    #
    # tl;dr: XXX: revert to commented code and upgrade jquery-rails when we upgrade to 3.2
    #
    # if Brooklyn::Application.config.assets.use_jquery_cdn
    #   javascript_include_tag(
    #     'https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js',
    #     'https://ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js')
    # else
    #   javascript_include_tag('jquery_all')
    # end
  end

  def rpxnow_include_tag(options = {})
    # this code is ripped out of rpxnow lib because it doesn't play nicely with our custom domain
    # and fixing it seems to require understanding of multiple side-effects
    options = {:width => '400', :height => '240'}.merge(options)
    url = "https://#{Brooklyn::Application.config.rpxnow.domain}/openid/embed?#{RPXNow.embed_params(email_accounts_url, options)}"
    content_tag(:iframe, '', src: url, scrolling: 'no', frameBorder: 'no', id: 'rpx_now_embed',
      style: "width:#{options[:width]}px;height:#{options[:height]}px;",
      allowtransparency: "allowtransparency")
  end

  def optimizely
    "//cdn.optimizely.com/js/#{Brooklyn::Application.config.optimizely.token}.js"
  end

  def optimizely_tag
    javascript_include_tag(optimizely) if feature_enabled?(:client, :optimizely)
  end

  def include_optimizely
    javascript(optimizely) if feature_enabled?(:client, :optimizely)
  end

  def ajax_overlay
    render "shared/ajax_overlay"
  end

  def link_to_help_center(text = 'Help Center')
    link_to text, Brooklyn::Application.config.urls.help, target: '_blank'
  end

  def link_to_email_us(text = 'Email Us')
    link_to text, Brooklyn::Application.config.urls.email
  end

  def link_to_payment_details(text = 'Payment Details')
    link_to text, Brooklyn::Application.config.urls.payment_details, target: '_blank'
  end

  def link_to_privacy_policy(text = 'Privacy Policy')
    link_to text, Brooklyn::Application.config.urls.privacy_policy, target: '_blank'
  end

  def link_to_terms(text = 'Terms')
    link_to text, Brooklyn::Application.config.urls.terms, target: '_blank'
  end

  def link_to_feedback(text)
    link_to text, Brooklyn::Application.config.urls.feedback, target: '_blank'
  end

  def link_to_transaction_policy(text = 'Transaction Policy')
    link_to text, Brooklyn::Application.config.urls.transaction_policy, target: '_blank'
  end

  def link_to_fees_explanation(text)
    link_to text, Brooklyn::Application.config.urls.fees_explanation, target: '_blank'
  end

  def link_to_payment_faq(text = 'Payment FAQ')
    link_to text, Brooklyn::Application.config.urls.payment_faq, target: '_blank'
  end

  def aviary_js
    external_javascript 'https://dme0ih8comzn4.cloudfront.net/js/featherssl.js'
  end

  def signup_links(options={})
    buttons = Network.registerable.map do |network|
      network_signup_button(network)
    end
    buttons.join(content_tag(:div, 'or', class: 'or-space')).html_safe
  end

  def if_feature_enabled(*args, &block)
    capture(&block).to_s if feature_enabled?(*args)
  end

  def unless_feature_enabled(*args, &block)
    capture(&block).to_s unless feature_enabled?(*args)
  end

  # Applies standard Rails simple formatting but completely sanitizes the text, allowing no tags whatsoever.
  def full_clean(text, html_options = {})
    simple_format(sanitize(text, tags: []), html_options, sanitize: false).html_safe
  end

  def display_mixpanel_banner
    content_for(:sponsors) do
      link_to(image_tag('//mixpanel.com/site_media/images/partner/badge_light.png', alt: 'Web Analytics',
        height: '36', width: '114'), 'http://mixpanel.com/f/partner')
    end
  end

  def spacer(text = nil, &block)
    content_tag(:span, class: 'spacer') do
      if text.present?
        text
      else
        yield if block_given?
      end
    end
  end

  def image_and_text(image, text, options = {})
    spacer = options.fetch(:spacer, ' ')
    [image_tag(image, alt: options[:alt] || text), text].join(spacer).html_safe
  end

  # Differs from +controller_name+ due to retaining the module namespace (eg +settings_profile_show+ instead of
  # +profile_show+).
  def full_action_name
    ("%s_%s" % [controller.class.name.sub(/Controller$/, '').underscore.gsub(/\//, '_'), action_name])
  end

  # Computes a unique class for the page's body tag based on the controller module and name and the action name.
  def body_class(value = nil)
    @body_class = value if value.present?
    @body_class ||= full_action_name
  end

  # Computes a unique name to be used as the "page_source" for a particular page. Should be
  # added to the body tag as a data-page-source attribute.
  def page_source(value = nil)
    @page_source = value if value.present?
    @page_source ||= full_action_name
  end

  def body_style(value = nil)
    @body_style = value if value.present?
    @body_style
  end

  def data_attrs(attrs)
    attrs.inject({}) {|a, kv| a["data-#{kv.first}"] = kv.last; a }
  end

  def nilhref
    'javascript:void(0)'
  end

  def use_content_class(klass)
    @content_class = klass
  end
  attr_reader :content_class

  # Pretty much the same as ActionView's +pluralize+, except the count is wrapped in a span with an emphasis class
  # applied.
  #
  # @param [Integer] count
  # @param [String] singular
  # @param [Hash] options
  # @option options [Boolean or String] :emphasis if +true+, applies the default emphasis class (+strong+) to the count;
  #   otherwise uses the option value as the class
  # @option options [String] :plural the plural form of the word, if the inflector's default is not acceptable
  # @see ActionView::Helpers::Text#pluralize
  def our_pluralize(count, singular, options = {})
    out = []
    count_text = (count || 0)
    if options[:emphasis]
      emphasis_class = options[:emphasis] == true ? 'strong' : options[:emphasis]
      out << content_tag(:span, count_text, class: emphasis_class)
    else
      out << count_text
    end
    # this line ripped straight out of ActionView
    out << ((count == 1 || count =~ /^1(\.0+)?$/) ? singular : (options[:plural] || singular.pluralize))
    out.join(' ').html_safe
  end

  def number_to_unitless_currency(amount, options = {})
    number_to_currency(amount, {unit: '', precision: 2}.merge(options))
  end

  # if the number is an even number of units use precision 0,
  # otherwise use precision 2
  def smart_number_to_currency(amount, options = {})
    precision = (amount * 100) % 100 != 0 ? 2 : 0
    number_to_currency(amount, {precision: precision}.merge(options))
  end

  def html_options_with_base_class(base_class, html_options = {})
    css_class = html_options.delete(:class) || ''
    css_class << " #{base_class}"
    html_options.merge!(:class => css_class.strip) if css_class.present?
    html_options
  end

  def qmark_tooltip(text)
    content_tag(:a, '?', :class => 'tooltip', :title => text, rel: 'tooltip')
  end

  def yes_no(boolean)
    boolean ? 'yes' : 'no'
  end

  def count_of_days_in_words(seconds, options = {})
    count = (seconds/1.day).ceil
    if options[:singular]
      "#{count} day"
    else
      pluralize(count, 'day')
    end
  end

  def count_of_hours_in_words(seconds, options = {})
    count = (seconds/1.hour).ceil
    if options[:singular]
      "#{count} hour"
    else
      pluralize(count, 'hour')
    end
  end

  def bank_account_number(last_four)
    "**** **** #{last_four}"
  end

  def content_tag_hidden_if(condition, *args, &block)
    content_tag_hidden_unless(!condition, *args, &block)
  end

  def content_tag_hidden_unless(condition, name, content_or_options_with_block = nil, options = nil, escape = true, &block)
    if block_given?
      options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
      content_or_options_with_block = capture(&block)
    end
    options ||= {}
    unless condition
      styles = options.delete(:style) || ''
      styles = styles.split(%r{;\s*})
      styles << 'display:none'
      options[:style] = styles.join(';')
    end
    content_tag(name, content_or_options_with_block, options, escape)
  end

  def content_or_none(value, options = {}, &block)
    if value.present?
      if block_given?
        capture { yield(value) }
      else
        value
      end
    else
      options.fetch(:message, 'None')
    end
  end

  def promo_banner(banner, options)
    return nil unless banner && banner.image
    options = options.dup
    options[:class] = "promo-banner #{options.delete(:class)}".strip
    image = image_tag(banner.image)
    content_tag(:div, options) do
      if banner.link.present?
        url = if banner.link.is_a?(Proc)
          instance_eval(&banner.link)
        else
          banner.link
        end
        link_options = {}
        link_options[:target] = banner.target if banner.target.present?
        link_to(image, url, link_options)
      else
        image
      end
    end
  end

  # @param [Hash] rules a map of CSS rule key/value pairs
  def style_attribute(rules)
    safe_join(rules.map { |rule| "#{rule.first}: #{rule.last}"}, '; ')
  end

  # @param [Array] classes a map of CSS class names
  def class_attribute(classes)
    classes.join(' ')
  end

  def bar_separated(*inputs)
    safe_join(Array.wrap(inputs).compact, content_tag(:span, raw('&nbsp;&nbsp;·&nbsp;&nbsp;')))
  end

  def flash_messages(options = {})
    hide = options.fetch(:hide, false)
    out = []
    {alert: :error, notice: :success, info: :info}.each_pair do |level, bootstrap_class|
      present = flash[level].present?
      alert_opts = {bootstrap_class => true, block: true, data: {role: "flash-#{level}"}, close: present && !hide}
      alert_opts[:style] = 'display:none' unless present && !hide
      out << content_tag(:div, data: {role: "alert-#{level}"}) do
        bootstrap_alert alert_opts do
          content_tag(:div, raw(flash[level])) if present && !hide
        end
      end
    end
    safe_join(out)
  end
end
