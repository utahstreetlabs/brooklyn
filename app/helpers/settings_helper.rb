module SettingsHelper
  def settings_email_choices
    choices = {}
    choices[:follow_me] = t('.choices.follow_me')
    choices[:listing_like] = t('.choices.listing_like')
    choices[:listing_share_facebook] = t('.choices.listing_share_facebook') if Network::Facebook.active?
    choices[:listing_share_twitter] = t('.choices.listing_share_twitter') if Network::Twitter.active?
    choices[:listing_comment] = t('.choices.listing_comment')
    choices[:listing_comment_reply] = t('.choices.listing_comment_reply')
    choices[:listing_mentioned] = t('.choices.listing_mentioned')
    choices[:invite_accept] = t('.choices.invite_accept')
    choices[:friend_join] = t('.choices.friend_join')
    choices[:listing_feature] = t('.choices.listing_feature')
    choices[:follower_list] = t('.choices.follower_list')
    choices[:connection_digest] = t('.choices.connection_digest') if feature_enabled?(:email, :connection_digest)
    choices[:site_news] = t('.choices.site_news')
    choices[:collection_follow] = t('.choices.collection_follow')
    choices[:listing_save] = t('.choices.listing_save')
    choices
  end

  def settings_disconnect_network_button(profile)
    text = t("settings.networks.#{profile.network}.disconnect", name: profile.name)
    link_to text, settings_network_path(profile), class: 'button right-button small soft disconnect remote-link',
      :'data-method' => :DELETE, rel: :nofollow, title: text
  end

  def settings_connect_network_button(network)
    text = t("settings.networks.#{network}.connect")
    options = network_options(network)
    css_classes = options.delete(:class) || ''
    css_classes << ' connect button right-button'
    options[:class] = css_classes
    options[:title] = text
    link_to_auth_path(text, network, options)
  end

  def credit_trigger_details(trigger)
    if trigger
      trigger_classname = trigger.class.name.demodulize
      attrs = {}
      case trigger_classname.to_sym
      when :InviterCreditTrigger
        user = User.find(trigger.invitee_id) if trigger.invitee_id
        attrs[:username] = user.name if user
      end
      translate(trigger_classname.underscore, attrs.merge(scope: 'settings.credits.triggers'))
    end
  end

  def settings_has_autoshare_choices?(network)
    # seems a little counter-intuitive, but +.present?+ on an empty array is false
    Network.klass(network).autoshare_events.present?
  end

  def settings_autoshare_choices(network)
    out = []
    Network.klass(network).autoshare_events.each do |event|
      label = t(event, scope: [:settings, :networks, network, :autoshare])
      checkbox_id = "user_autoshare_prefs_#{event}_#{network}"
      field_name = "user[autoshare_prefs][#{event}]"
      out << content_tag(:li) do
        content = hidden_field_tag(field_name, '0', id: "#{checkbox_id}_hidden")
        content << check_box_tag(field_name, '1', current_user.allow_autoshare?(event, network), id: checkbox_id)
        content << label_tag(checkbox_id, label, class: 'checkbox')
        content
      end
    end
    safe_join(out)
  end

  def autoshare_auth_header(profile, &block)
    if profile.network == :facebook
      content_tag :div, :'data-role'=>'autoshare-content', :'data-auth-path'=>autoshare_auth_path(profile),
      :'data-timeline-disable-url'=> disable_timeline_settings_networks_path,
      :'data-timeline-permission-url' => timeline_permission_settings_networks_path(id: profile.id), &block
    else
      content_tag :div, &block
    end
  end

  def autoshare_auth_path(profile)
    auth_path(profile.network, scope: "publish_actions", d: callbacks_facebook_connected_path)
  end

  def link_to_delete_address(address, options = {})
    link_to 'Delete', settings_shipping_address_path(address.id), options.merge(class: 'delete positive', :'method' => :DELETE,
      :'data-confirm' => 'Are you sure you want to delete this shipping address?')
  end

  def link_to_make_default_address(address, options = {})
    link_to 'Make Default', settings_shipping_address_default_path(address.id), options.merge(:'method' => :PUT)
  end

  def address_label_name(address)
    "#{address.name}" + (address.default_address ? " (#{t("settings.addresses.default_address")})" : "")
  end

  def seller_info_settings_progress_bar(step)
    items = [
      [t('.progress_bar.step1'), nil, {active: (step == :step1)}],
      [t('.progress_bar.step2'), nil, {active: (step == :step2)}]
    ]
    bootstrap_tabs(items, id: 'seller-identity-bar')
  end
end
