module InvitesHelper
  # invites section

  def number_to_invite_credit_currency(amount)
    smart_number_to_currency amount,
      format: %q[%u<span class="strong">%n</span>]
  end

  # invite your friends module

  def invite_suggestions(suggestions, options = {}, &b)
    options.merge!(class: 'rep-list',
                   :'data-more' => dashboard_invites_suggestions_path(blacklist: suggestions.map(&:id)))
    content_tag(:ul, options, &b)
  end

  def invite_button(profile, options = {})
    if options[:invited]
      link_to 'Invitation Sent', dashboard_invites_profile_path(profile.id),
        :class => 'button invite rep-act remote-link disabled', rel: :nofollow,
        remote: true
    else
      link_to 'Invite', dashboard_invites_profile_path(profile.id),
        :class => 'button invite rep-act remote-link', rel: :nofollow,
        data: {method: :put, type: :json, id: profile.id, role: 'invite'},
        remote: true
    end
  end

  def link_to_delete_invite_suggestion(id)
    link_to image_tag('icons/close-content-hover.png'), dashboard_invites_suggestion_path(id),
      remote: true, method: :DELETE, class: 'rep-remove remote-link', title: 'remove', :'data-id' => id
  end

  def invite_friend_pileon(inviter, invitee, options = {})
    capture { render "/shared/invite_friend_pileon", options.merge(inviter: inviter, invitee: invitee) }
  end

  def invite_friend(suggestion, options = {})
    capture { render "/shared/invite_friend", options.merge(profile: suggestion) }
  end

  def invite_acceptance_progress_bar(viewer)
    out = []
    out << content_tag(:h4, class: 'margin-bottom-half') do
      raw(t('shared.invites.progress.invites_credited', count: viewer.credited_invite_acceptance_count,
        cap: viewer.credited_invite_acceptance_cap))
    end
    out << bootstrap_progress_bar(viewer.credited_invite_acceptance_percent)
    if viewer.credited_invite_acceptance_capped?
      out << content_tag(:p, raw(t('shared.invites.progress.capped')), class: 'invade-top margin-bottom')
    end
    safe_join(out, '')
  end

  def invite_modal_invite_button(text, options = {})
    data = {action: 'invite-cta', target: '#invite-friends-modal'}
    data.merge!(toggle: :modal) if current_user.connected_to?(Network::Facebook)
    bootstrap_button(text, '#', class: options[:class] || 'primary xlarge', data: data)
  end

  # @option options [FacebookU2uRequest] :request a U2U request representing a successful FB request, causing the
  #                                               invite bar to be rendered in the "after" state
  # @option options [String] :source a string identifying the placement of the invite bar (eg +feed+
  #                                  denoting the feed page)
  def invite_bar(viewer, options = {})
    return unless feature_enabled?('invites.bar')
    return unless viewer.connected_to?(Network::Facebook)
    return if invite_bar_closed?
    return if FacebookU2uInvite.count_complete(sender: viewer) >=
      Brooklyn::Application.config.invite_bar.max_acceptances

    mp_options = {
      share_channel: 'facebook_requests'
    }
    mp_options[:source] = options[:source] if options[:source]
    mp_view_event('invite_bar', options)

    # see controls/invite-bar for data api reference
    data = {
      role: 'invite-bar',
      source: 'invite_bar'
    }
    # ignore FB users who have been invited by the viewer recently
    excludes = viewer.u2u_invite_excludes
    data[:exclude] = excludes.join(',') if excludes.any?
    # XXX: turn this into a bootstrap alert (with a custom close button since we need to fire an ajax request before
    # dismissing the alert)
    classes = %w(invite-banner)
    classes << 'ff-tutorial-bar' if feature_enabled?(:onboarding, :tutorial_bar)
    content_tag(:div, data: data, class: class_attribute(classes)) do
      content_tag(:div, class: 'invite-banner-content') do
        out = []
        if options[:request] # "after" state
          out << content_tag(:button, '', class: 'close-button', data: {dismiss: 'invite-bar'})
          out << content_tag(:p, t('invite_bar.after.description', count: options[:request].invite_count,
                                   value: smart_number_to_currency(options[:request].amount_for_accepted_invites)))
          out << invite_modal_invite_button(t('invite_bar.after.button'))
        else # "before" state
          out << content_tag(:p, t('invite_bar.before.description_html', amount: smart_number_to_currency(Credit.amount_for_accepted_invite)))
          out << invite_modal_invite_button(t('invite_bar.before.button'))
        end
        safe_join(out)
      end
    end
  end

  def invite_modal_invite_suggestions(suggestions, viewer, options)
    content_tag(:ul, id: 'invite-friends-list') do
      s = suggestions.map do |profile|
        content_tag(:li, data: {role: 'selectable'}) do
          out = []
          out << content_tag(:div, class: 'avatar-container') do
            profile_avatar(profile)
          end
          out << content_tag(:div, class: 'invitee-name-container') do
            content_tag(:div, profile.name, class: 'invitee-name')
          end
          out << check_box_tag(profile.uid)
          safe_join(out)
        end
      end
      safe_join(s)
    end
  end

  def invite_modal_select_all
    content_tag(:div, class: 'select-all-container') do
      check_box_tag('select_all', 'select_all', data: {role: 'select-all-suggestions'}) +
        label_tag('select_all', t('invite_modal.buttons.select_all'))
    end
  end

  def invite_modal_search_box
    content_tag(:div, id: 'fb-friend-search') do
      bootstrap_form_tag(nilhref, id: 'search-form', remote: true) do
        out = []
        out << content_tag(:div, class: 'pull-left') do
          bootstrap_text_field_tag(:name, nil, placeholder: t('invite_modal.search.placeholder'), id: 'search-string')
        end
        out << button_tag('Search', class: 'button', id: 'fb-friend-search-button')
        safe_join(out)
      end
    end
  end

  def invite_friends_modal(viewer, options = {})
    data = {
      message: t('invite_modal.requests.message', inviter: viewer.name),
      role: 'invite-modal'
    }

    # if the user isn't connected to facebook, use the fb invite dialog, which doesn't use our
    # invite suggestions
    data['use-fb-dialog'] = true if !feature_enabled?(:invites, :custom_modal) || !viewer.connected_to?(Network::Facebook)

    # ignore FB users who have been invited by the viewer recently
    excludes = viewer.u2u_invite_excludes
    data[:exclude] = excludes.join(',') if excludes.any?

    bootstrap_modal('invite-friends', t('invite_modal.title'), save_button_text: t('invite_modal.buttons.save'),
                    custom_links: invite_modal_select_all, show_close: false, data: data.merge(options[:data] || {}),
                    remote: true) do
      out = []
      out << content_tag(:p, t('invite_modal.description_html', amount: smart_number_to_currency(Credit.amount_for_accepted_invite)))

      out << content_tag(:div, data: {role: 'multi-friend-selector'}, id: 'invite-friends-container') do
        out2 = []
        out2 << content_tag(:div, class: 'nav-container nav-container-small') do
          content_tag(:ul, :class => 'nav-tabs copious-tabs') do
            feeds = []
            feeds << content_tag(:li, t('invite_modal.recommended_tab'), class: 'selected')
            feeds << content_tag(:div, invite_modal_search_box)
            safe_join(feeds)
          end
        end
        out2 << form_tag(nilhref, data: {role: 'selectables', condition: :primary}, class: 'invite-friends-list') { '' }
        safe_join(out2)
      end

      safe_join(out)
    end
  end

  # recommendation is currently a special case of invitation, so keep it here for now
  def recommend_button(options = {})
    data = options.fetch(:data, {}).reverse_merge(
      action: 'recommend-cta',
      target: options.fetch(:target, '#recommend-listing-modal')
    )
    data[:toggle] = :modal if current_user.connected_to?(Network::Facebook)
    classes = 'button primary full-width '
    classes << 'on-hover-button' if options[:on_hover_button]
    bootstrap_button('', class: classes, data: data) do
      out = []
      out << content_tag(:span, '', class: 'icon-recommend')
      out << t('listings.recommend_button')
      safe_join(out)
    end
  end

  def recommend_modal(viewer, listing, options = {})
    data = {
      message: t('recommend_modal.requests.message', recommender: viewer.name, listing: listing.title),
      role: 'recommend-modal'
    }

    # if the user isn't connected to facebook, use the fb invite dialog, which doesn't use our
    # invite suggestions
    data['use-fb-dialog'] = true if !feature_enabled?(:invites, :custom_modal) || !viewer.connected_to?(Network::Facebook)

    # ignore FB users who have been invited by the viewer recently
    excludes = viewer.u2u_invite_excludes
    data[:exclude] = excludes.join(',') if excludes.any?

    bootstrap_modal(options[:id] || 'recommend-listing', t('recommend_modal.title'), save_button_text: t('recommend_modal.buttons.save'),
                    custom_links: invite_modal_select_all, show_close: false, data: data.merge(options[:data] || {}),
                    remote: true) do
      out = []
      out << content_tag(:p, t('recommend_modal.description_html', amount: smart_number_to_currency(Credit.amount_for_accepted_invite)))

      out << content_tag(:div, data: {role: 'multi-friend-selector'}, id: 'recommend-container') do
        out2 = []
        out2 << content_tag(:div, id: 'recommend-listing-container', class: 'card-container-v4') do
          item = []
          item << content_tag(:div, class: 'product-image-container') do
            listing_photo_tag(options[:photo] || listing.photos.first, :medium, title: listing.title, class: 'product-image')
          end
          item << content_tag(:div, class: 'product-info') do
            item2 = []
            item2 << content_tag(:span, listing.title, class: 'product-title ellipsis')
            item2 << content_tag(:div, class: 'price-box') do
              content_tag(:span, number_to_currency(listing.price), class: 'price')
            end
            safe_join(item2)
          end
          safe_join(item)
        end
        out2 << form_tag(nilhref, data: {role: 'selectables', condition: :primary}, class: 'invite-friends-list') { '' }
        safe_join(out2)
      end

      safe_join(out)
    end
  end
end

