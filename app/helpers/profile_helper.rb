module ProfileHelper
  # manually render postal address errors
  # XXX: figure out why rails isn't setting the correct
  #      keys to make this work ootb
  def postal_address_errors(user)
    Hash[user.errors.select {|k, _| k.to_s.starts_with? 'postal_address' }].values
  end

  def profile_open_graph_tags(user, options = {})
    out = []
    out << tag(:meta, property: 'og:type', content: 'profile')
    out << tag(:meta, property: 'fb:app_id', content: Network::Facebook.app_id)
    out << tag(:meta, property: 'fb:admins', content: Network::Facebook.open_graph_admins)
    out << tag(:meta, property: 'og:title', content: user.name)
    out << tag(:meta, property: 'og:image', content: absolute_url(user_profile_canonical_photo_url(user)))
    out << tag(:meta, property: 'og:url', content: public_profile_url(user))
    out << tag(:meta, property: 'og:site_name', content: 'Copious')
    out << tag(:meta, property: 'og:description', content: t('profile.show.open_graph.description', name: user.name))
    out << tag(:meta, property: 'profile:first_name', content: user.firstname)
    out << tag(:meta, property: 'profile:last_name', content: user.lastname)
    out << tag(:meta, property: 'profile:username', content: user.slug)
    out << tag(:meta, property: 'fb:profile_id', content: options[:fb_profile].uid) if options[:fb_profile]
    safe_join(out)
  end

  def profile_follow_box(user, viewer)
    content_tag(:div, data: {role: 'profile-follow-box'}, class: 'cta-right-container') do
      out = ''.html_safe
      if viewer
        unless user.blocking?(viewer)
          out << follow_control(user, viewer, follower_count_selector: '[data-role=profile-followers-count]')
        end
      else
        out << link_to('Follow', signup_path_with_flow_destination(s: 'b'),
          :class => 'button positive follow left clear', rel: :nofollow, data: {action: :follow})
      end
      out
    end
  end

  def profile_block_box(user, viewer)
    content_tag(:div, data: {role: 'profile-block-box'}, class: 'user-block-container') do
      content_tag(:span, id: 'block', data: {:'follower-count' => '[data-role=profile-followers-count]'}) do
        capture { render 'shared/block_button', blockee: user, blocker: viewer }
      end
    end
  end

  def profile_edit_profile_box
    content_tag :div, :class => 'cta-right-container' do
      link_to 'Edit profile', settings_profile_path, :class => 'button edit_profile'
    end
  end

  def profile_dual_connection_signal_box(viewer, profile_user, connection)
    content_tag(:div, id: 'shared-connections-container') do
      content_tag(:div, id: 'your-connections-container') do
        content_tag(:div, id: 'your-connections') do
          content_tag(:span) do
            number_to_connection_signal(viewer ? viewer.person.connection_count : nil)
          end +
          content_tag(:h5, 'You')
        end
      end +
      content_tag(:div, id: 'seller-connections-container') do
        content_tag(:div, id: 'seller-connections') do
          content_tag(:span, number_to_connection_signal(profile_user.person.connection_count)) +
          content_tag(:h5, profile_user.firstname)
        end
      end +
      content_tag(:div, id: 'shared-connections') do
        content_tag(:div, id: 'shared-stats-container') do
          content_tag(:span, id: 'shared-stats') do
            number_to_connection_signal(connection ? connection.shared_count : nil)
          end
        end +
        content_tag(:div, id: 'shared-textarea') do
          content_tag(:span, 'SHARED', id: 'shared') +
          connection_signal_image_tag(connection) +
          content_tag(:span, id: 'connections') do
            (connection ? connection.shared_count : 0) == 1 ? 'connection' : 'connections'
          end
        end
      end +
      content_tag(:div, id: 'signal-rule') do
        content_tag(:div, nil, :class => 'arrow-border') +
        content_tag(:div, nil, :class => 'arrow')
      end
    end
  end

  def profile_social_network_box(profiles, options = {})
    # would love to break this up into separate methods for connected and unconnected, but the dashboard still uses
    # a single widget with both types interspersed
    profiles ||= {}
    with_connected = options.fetch(:connected, true)
    with_unconnected = options.fetch(:unconnected, true)
    content_tag :ul, class: 'connected-network-list' do
      Network.active.inject(''.html_safe) do |m, network|
        # can't use Array.wrap(profiles[network]) because that turns nil into [] rather than [nil]
        network_profiles = profiles[network].is_a?(Array) ? profiles[network] : [profiles[network]]
        network_profiles.each do |profile|
          if profile && profile.connected? && with_connected
            m << content_tag(:li, :class => 'connected-list-container') do
              link_to_network_icon(network, profile, class: 'connected-network-icon') +
              content_tag(:div, :class => 'networks-text') do
                network_connections(profile)
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

  def profile_self_connection_signal_box(viewer)
    content_tag(:div, id: 'shared-connections-container') do
      content_tag(:div, id: 'total-connections') do
        content_tag(:div, id: 'shared-stats-container') do
          content_tag(:span, number_to_connection_signal(current_user.person.connection_count), id: 'shared-stats')
        end +
        content_tag(:div, id: 'shared-textarea') do
          content_tag(:span, 'Total Number of Connections', id: 'shared')
        end
      end +
      content_tag(:div, id: 'signal-rule') do
        content_tag(:div, nil, :class => 'arrow-border') +
        content_tag(:div, nil, :class => 'arrow') +
        content_tag(:p, :class => 'connect-suggest') do
          "The Copious Signal shows how connected you are to other users on Copious. The more connections, the more comfortable buyers and sellers feel."
        end
      end
    end
  end

  def profile_tabs(profile_user)
    tab_items = [{
      text: t('profiles.tabs.listings_html', count: listings_count),
      href: public_profile_path(profile_user),
      link: {unless_current: true}
    }]

    if feature_enabled?('collections.page')
      tab_items << {
        text: t('profiles.tabs.collections_html', count: collections_count),
        href: public_profile_collections_path(profile_user),
        link: {unless_current: true}
      }
    end

    tab_items << {
      text: t('profiles.tabs.likes_html', count: liked_count),
      href: liked_public_profile_path(profile_user),
      link: {unless_current: true}
    }

    following_active = current_page?(collections_public_profile_following_path(profile_user)) ||
      current_page?(people_public_profile_following_path(profile_user))
    tab_items << bootstrap_dropdown_list_item(t('profiles.tabs.following.label_html', count: following_count),
      [{
         text: t('profiles.tabs.following.collections', count: following_collections_count),
         href: collections_public_profile_following_path(profile_user)
       },
       {
         text: t('profiles.tabs.following.people', count: following_people_count),
         href: people_public_profile_following_path(profile_user)
       }],
      active: following_active, toggle: {caret: true}, menu: {item: {with_active: false}})

    tab_items << {
      text: t('profiles.tabs.followers_html', count: followers_count),
      href: followers_public_profile_path(profile_user),
      link: {unless_current: true}
    }

    if logged_in? && feature_enabled?(:feedback)
      tab_items << {
        text: t('profiles.tabs.feedback'),
        href: selling_public_profile_feedback_index_path(profile_user),
        link: {unless_current: true}
      }
    end

    bootstrap_tabs(tab_items)
  end

  def profile_user_strip(strip, viewer, profile_user)
    content_tag(:li, :class => 'user-strip', data: {role: 'user-strip', user: strip.user_id,
        following: strip.viewer_following?}) do

      content_tag(:div, :class => 'pull-left') do
        content_tag(:div, :class => 'avatar-container pull-left') do
          user_avatar_small(strip.user, :class => 'text-adjacent')
        end +
        content_tag(:div, :class => 'pull-left this-one') do
          profile_user_strip_info(strip)
        end
      end +
      content_tag(:div, :class => 'pull-right') do
        profile_user_strip_user_follow(strip, viewer, profile_user) +
        profile_user_strip_listings(strip)
      end
    end
  end

  def profile_user_strip_info(strip)
    content_tag(:div, :class => 'pull-left') do
      link_to_user_profile(strip.user) do
        content_tag(:h4, strip.user.name, class: 'ellipsis')
      end + profile_user_strip_stats(strip)
    end
  end

  def profile_user_strip_user_follow(strip, viewer, profile_user)
    if strip.user == viewer
      ''.html_safe
    else
      profile_user_strip_follow_button(strip, viewer, profile_user)
    end
  end

  def profile_user_strip_follow_button(strip, viewer, profile_user, options={})
    button_class = 'button follow-button large ' + options[:class].to_s
    if viewer
      if strip.viewer_following?
        button_class << ' following disabled actionable'
        button_text = 'Following'
        method = :DELETE
        path = public_profile_followee_path(profile_user, strip.user, page_source: 'profile')
      else
        button_text = 'Follow'
        method = :PUT
        path = public_profile_followee_path(profile_user, strip.user, page_source: 'profile')
      end
      link_to(button_text, path, id: "follow-button-#{strip.user.id}", :class => button_class, remote: true,
        rel: :nofollow, data: {method: method, type: :json})
    else
      button_class << ' primary'
      link_to('Follow', signup_path_with_flow_destination(s: 'b'), :class => button_class, rel: :nofollow,
        data: {:'user-strip' => strip.user.id, action: :follow})
    end
  end

  def profile_user_strip_stats(strip, options={})
    hide_labels = options[:hide_labels]
    content_tag(:ul, :class => 'nav nav-vertical-list nav-stats kill-margin-bottom pull-left ' + options[:class].to_s) do
      content_tag(:li, :class => 'stats-sale') do
        link_to(public_profile_path(strip.user)) do
          out = ''.html_safe
          out << content_tag(:span, strip.listings_count, data: {role: 'listings-count'})
          out << 'LISTINGS: ' unless hide_labels
          out
        end
      end +
      content_tag(:li, :class => 'stats-like') do
        link_to(liked_public_profile_path(strip.user)) do
          out = ''.html_safe
          out << content_tag(:span, strip.liked_count, data: {role: 'liked-count'})
          out << 'LOVES: ' unless hide_labels
          out
        end
      end +
      content_tag(:li, :class => 'stats-following') do
        link_to(people_public_profile_following_path(strip.user)) do
          out = ''.html_safe
          out << content_tag(:span, strip.following_count, data: {role: 'following-count'})
          out << 'FOLLOWING: '
          out
        end
      end +
      if options[:hide_followers].nil?
        content_tag(:li, :class => 'stats-followers') do
          link_to(followers_public_profile_path(strip.user)) do
            out = ''.html_safe
            out << content_tag(:span, strip.followers_count, data: {role: 'followers-count'})
            out << 'FOLLOWERS: '
            out
          end
        end
      end
    end
  end

  def profile_user_strip_listings(strip)
    content_tag(:ul, :class => 'pull-left thumbnails') do
      strip.photos.each.with_index.inject(''.html_safe) do |m, (photo, i)|
        m << content_tag(:li) do
          link_to(listing_photo_tag(photo, :medium), listing_path(strip.listings[i],
            src: "public-profile-#{strip.user.slug}"), :class => 'thumbnail')
        end
      end
    end
  end

  def profile_banner(user, options = {})
    promo_banner(Brooklyn::Application.config.banners.profile[user.slug], options)
  end
end
