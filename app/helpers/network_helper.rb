module NetworkHelper
  # @options options [Boolean] :connected (true) whether or not to include connected networks in the list
  # @options options [Boolean] :unconnected (true) whether or not to include unconnected networks (no profile, or
  #   disconnected profile) in the list
  def social_networks(profiles, options = {})
    # would love to break this up into separate methods for connected and unconnected, but the dashboard still uses
    # a single widget with both types interspersed
    profiles ||= {}
    with_connected = options.fetch(:connected, true)
    with_unconnected = options.fetch(:unconnected, true)
    content_tag :div, class: 'network' do
      content_tag :ul, class: 'connected-network-list' do
        Network.active.inject(''.html_safe) do |m, network|
          # can't use Array.wrap(profiles[network]) because that turns nil into [] rather than [nil]
          network_profiles = profiles[network].is_a?(Array) ? profiles[network] : [profiles[network]]
          network_profiles.each do |profile|
            if profile && profile.connected? && with_connected
              m << content_tag(:div, :class => 'connected-list-container') do
                link_to_network_icon(network, profile) +
                content_tag(:div, :class => 'networks-text') do
                  link_to_network_profile(profile) + tag(:br) + network_connections(profile)
                end
              end
            elsif logged_in? && !(profile && profile.connected?) && with_unconnected
              m << content_tag(:li, :class => 'connect-network') do
                link_to_network_connect(network)
              end
            end
          end
          m
        end
      end
    end
  end

  def link_to_network_icon(network, profile = nil, options = {})
    text = content_tag(:span, '', class: "connected-network #{network.to_s}")
    if profile && profile.connected? && profile.profile_url.present?
      link_to(text, profile.profile_url, {target: '_blank'}.merge(options))
    else
      text
    end
  end

  def link_to_network_profile(profile, options = {})
    text = profile.name || 'Profile'
    if profile.profile_url
      link_to text, profile.profile_url, {target: '_blank'}.merge(options)
    else
      content_tag :span, text, :class=> "unlinked-profile"
    end
  end

  def link_to_network_connect(network, options = {})
    text = content_tag(:div, '', class: "connect-this #{network.to_s}") +
      content_tag(:span, "Connect my #{t(:name, scope: [:networks, network])}")
    options = network_options(network)
    css_classes = options.delete(:class) || ''
    css_classes << ' button connect small'
    options[:class] = css_classes
    link_to_auth_path(text, network, options)
  end

  def link_to_auth_path(text, network, options = {})
    if network == :facebook
      link_to_facebook_connect(options.merge(label: text, show_image: false))
    else
      link_to text, auth_path(network), options
    end
  end

  def network_signup_button(network=nil, options = {})
    options = options.reverse_merge(scope: :signup)
    cl = options.fetch(:class, "button primary large positive #{network} signup")
    content = options.fetch(:content, image_and_text("social_networks/loh-#{network}-icon.png",
      t("shared.messages.#{options[:scope]}.#{network}")))
    if network == :facebook
      content_tag(:button, content, facebook_auth_params(options).merge(class: cl))
    else
      content_tag(:button, content, name: :network, value: network, data: { :role => "auth-#{network}" }, :class => cl)
    end
  end

  def profile_name(profile, network=nil)
    network = network || profile.network
    translate("networks.#{network}.name")
  end

  def network_connect_status(content)
    content_tag(:span, content, class: 'status')
  end

  def network_options(network)
    if network == :instagram
      {'data-auth-path' => auth_path(network)}
    else
      {}
    end.merge(class: "connect_#{network}")
  end

  def network_connections(profile)
    t("networks.connections.#{[profile.network, profile.type].compact.join '_'}", count: profile.connection_count,
      target: 'this')
  end

  def profile_avatar(profile, options = {})
    alt = t(:user_on_network, name: profile.name, network: t(:name, scope: [:networks, profile.network]),
      scope: [:dashboard, :who_to_follow])
    title = profile.name
    img_options = {class: 'icon', height: 30, width: 30, alt: alt, title: title}.merge(options)
    # remove the scheme from the photo url so the browser will use the scheme of the enclosing page
    # also use width option to give FB a hint how large the square image should be
    photo_url = profile.typed_photo_url(:square, width: img_options[:width]).gsub(/^http:/, '')
    image_tag(photo_url, img_options)
  end

  def link_to_profile_avatar(profile, options = {})
    avatar_options = options.delete(:img) || {}
    link_to_profile(profile, profile_avatar(profile, avatar_options), options)
  end

  def link_to_profile(profile, text = nil, options = {})
    text ||= profile.name
    link_to text, profile.profile_url, options.merge(target: '_blank')
  end
end
