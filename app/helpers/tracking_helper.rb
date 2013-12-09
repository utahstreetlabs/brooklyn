module TrackingHelper
  def google_analytics_config
    raw("GA_ACCOUNT = '#{Brooklyn::Application.config.google_analytics.account_id}';")
  end

  def mixpanel_config
    raw("MP_TOKEN = '#{Brooklyn::Application.config.tracking.mixpanel.token}';")
  end

  def adroll_config
    config = Brooklyn::Application.config.tracking.adroll
    js = []
    js << raw(%Q{adroll_adv_id = '#{config.adv_id}';})
    js << raw(%Q{adroll_pix_id = '#{config.pix_id}';})
    js << raw(%Q{adroll_segments = '#{@adroll_segment}';}) if @adroll_segment
    js << raw(%Q{adroll_conversion_value_in_dollars = #{@adroll_conversion_value};}) if @adroll_conversion_value
    js << raw(%Q{adroll_custom_data = {'ORDER_ID': '#{@adroll_order_id}'};}) if @adroll_order_id
    safe_join(js, "\n")
  end

  def tracking_config
    js = []
    js << google_analytics_config
    js << mixpanel_config
    js << adroll_config
    safe_join(js, "\n")
  end

  # record this page view as an event in mp
  # formatting wrapper for all the places we are already using this, but 'yyy view' is not always what we want
  def mp_view_event(page, opts = {})
    # get identification in before tracking, name tagging for the user
    # stream appears to need to happen before the tracking event
    mp_identify
    mp_track_js_event("#{page} view", opts)
  end

  def mp_track_js_event(event_label, opts = {})
    #XXX - augment opts with participating vanity experiments if possible
    script do
      raw("copious.track('#{event_label}', #{opts.to_json});")
    end
  end

  # provides a consistent identity for users in mixpanel. should be used on every page in order to
  # get mixpanel page tracking working. according to the mixpanel docs it can be called any time in
  # in the page-lifecycle, btu experimentation suggests that name_tag should be called before
  # tracking events to get stream tracking working properly, so it can be called explicitly before
  # tracking events to ensure it runs first.
  def mp_identify
    return if @mp_identified
    @mp_identified = true
    js = []
    js << raw(%Q{mixpanel.identify('#{visitor_identity}');})
    js << raw(%Q{mixpanel.set_config({loaded: window.mixpanelOnLoad})})

    if current_user and current_user.registered?
      js << raw(%Q{mixpanel.people.set({
  '$first_name': '#{j(current_user.firstname)}',
  '$last_name': '#{j(current_user.lastname)}',
  'profile': '#{public_profile_url current_user}',
  'remember_me_created_at': '#{current_user.remember_created_at.to_s}',
  '$email': '#{current_user.email}',
  '$created': '#{current_user.created_at.to_s}',
  '$last_login': '#{Time.now.to_s}'
});
mixpanel.name_tag('#{current_user.slug}');
})
    end
    # render superproperty js and clear them from our session
    js << raw(mixpanel_superproperty_js)
    forget_mp_superproperties
    script do
      safe_join(js, "\n")
    end
  end

  def ga_view_event(category, event, opts = {})
    opts = { identify: true }.merge(opts)
    js = []
    js << raw("$(function() {")
    js << raw("_gaq.push(['_trackEvent', '#{category}', '#{event}']);")
    js << raw("});")
    script do
      js.join
    end
  end

  def if_tracking_enabled
    if feature_enabled?(:client, :tracking)
      yield
    end
  end

  # Tracking pixel code for google adwords.
  def adwords_tracking_img_tag(conversion_id, conversion_label, options = {})
    if_tracking_enabled do
      src = raw("//www.googleadservices.com/pagead/conversion/#{conversion_id}/?label=#{conversion_label}&guid=ON&script=0")
      image_tag(src, {:alt => ''}.merge(options))
    end
  end

  def adwords_tracking_pixel(key, value=nil)
    if_tracking_enabled do
      value ||= 0
      args = Brooklyn::Application.config.tracking.google.adwords.send(key)
      text = []
      text << javascript_tag do
        raw <<-CODE
          var google_conversion_id = #{args.conversion_id};
          var google_conversion_language = 'en';
          var google_conversion_format = '3';
          var google_conversion_color = 'ffffff';
          var google_conversion_label = '#{args.conversion_label}';
          var google_conversion_value = #{value};
        CODE
      end
      external_javascript '//www.googleadservices.com/pagead/conversion.js'

      text << content_tag(:noscript) do
        content_tag(:div, :style=>"display:inline;") do
          adwords_tracking_img_tag(args.conversion_id, args.conversion_label,
            {:height => 1, :width => 1, :style => 'border-style:none;', :alt => ''}).html_safe
        end
      end

      safe_join(text)
    end
  end

  def optimal_tracking_pixel(key, val)
    if_tracking_enabled do
      src = "//t.optorb.com/cv?co=#{Brooklyn::Application.config.tracking.optimal.id}&ev=#{key}&am=#{val}"
      image_tag(src, alt: '', width: 1, height: 1)
    end
  end

  def adroll_track(segment, options = {})
    @adroll_segment = segment
    @adroll_conversion_value = options[:conversion_value] if options[:conversion_value].present?
    @adroll_order_id = options[:order_id] if options[:order_id].present?
  end

  # XA.net is a firm that does tracking for facebook campaigns
  def xanet_tracking_pixel(options = {})
    if_tracking_enabled do
      src = "//t.orbengine.com/cv?co=#{Brooklyn::Application.config.tracking.xanet.id}&am=#{Brooklyn::Application.config.tracking.xanet.val}"
      image_tag(src, {id: 'xanet-pixel', alt: '', height: '1', width: '1'}.merge(options))
    end
  end

  def mediaforge_retargetting_js(params={})
    if_tracking_enabled do
      external_javascript "https://tags.mediaforge.com/js/480?#{params.to_query}"
    end
  end

  def registration_trackers
    out = []
    out << adwords_tracking_pixel(:registration)
    out << xanet_tracking_pixel
    out << optimal_tracking_pixel(:registration, '0.00')
    safe_join(out)
  end

  def listing_activation_trackers
    out = []
    out << optimal_tracking_pixel(:listing, '1.00')
    safe_join(out)
  end
end
