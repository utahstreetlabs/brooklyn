# NOTE: flip behavior is disabled as per https://www.pivotaltracker.com/story/show/45652601

module InviteCardHelper
  # FB FEED DIALOG INVITE CARD

  def fb_feed_dialog_invite_card(card, options = {})
    mp_view_event('invite_card', source: 'feed', share_channel: 'facebook_feed')
    invite_card_container(card, 'fb-feed-dialog-invite') do
      out = []
      out << fb_feed_dialog_invite_card_photo(card, options)
      out << fb_feed_dialog_invite_card_info(card, options)
      out << fb_feed_invite_card_story(card, options)
      out << fb_feed_invite_card_credits(card, options)
      out << fb_feed_dialog_invite_card_actions(card, options)
      safe_join(out)
    end
  end

  # not used
  def fb_feed_dialog_invite_card_story(card, options = {})
    content_tag(:div, class: 'feed-container') do
      if card.story
        fb_feed_dialog_invite_card_link do
          content_tag(:div, '', class: 'avatar-container') do
            content_tag(:span, '', class: 'avatar text-adjacent from-copious')
          end +
          content_tag(:div, class: 'feed-story-container') do
            content_tag(:span, class: 'feed-story', data: {role: 'feed-story'}) do
              t('facebook_feed_dialog_invite_card.story_html')
            end
          end
        end
      end
    end
  end

  def fb_feed_dialog_invite_card_photo(card, options = {})
    content_tag(:div, class: 'product-image-container') do
      fb_feed_dialog_invite_card_link do
        image_tag('icons/invite-cards/invite-cards-fb.jpg', width: '300', height: '300')
      end
    end
  end

  def fb_feed_dialog_invite_card_info(card, options = {})
    content_tag(:div, class: 'product-info') do
      fb_feed_dialog_invite_card_link do
        content_tag(:span, class: 'product-title') do
          t('facebook_feed_dialog_invite_card.story_html')
        end
      end
    end
  end

  def fb_feed_invite_card_story(card, options = {})
    content_tag(:div, class: 'social-story-container') do
      fb_feed_dialog_invite_card_link do
        out = []
        out << content_tag(:span, class: 'social-story') do
          t('facebook_feed_dialog_invite_card.invite_story',
            amount: smart_number_to_currency(Credit.amount_for_accepted_invite))
        end
        safe_join(out)
      end
    end
  end

  def fb_feed_invite_card_credits(card, options = {})
    content_tag(:div, class: 'price-box') do
      fb_feed_dialog_invite_card_link do
        out = []
        out << content_tag(:div, class: 'invite-credit-limit') do
          out2 = []
          out2 << tag(:hr)
          out2 << content_tag(:span, t('facebook_facepile_invite_card.front.invite_credit_limit',
            amount: smart_number_to_currency(Credit.max_inviter_credits_per_invitee)), class: 'invite-credit-limit')
          safe_join(out2)
        end
        safe_join(out)
      end
    end
  end

  def fb_feed_dialog_invite_card_actions(card, options = {})
    content_tag(:div, class: 'product-action-area') do
      fb_feed_dialog_invite_card_link do
        bootstrap_button(action_type: :social, size: :small, type: :button) do
          out = []
          out << content_tag(:span, nil, class: 'icons-invite-fb')
          out << t('facebook_feed_dialog_invite_card.button')
          safe_join(out)
        end
      end
    end
  end

  def fb_feed_dialog_invite_card_link(&block)
    link_options = {
      class: 'share',
      target: '_blank',
      data: {action: 'fb-feed-dialog-share'}
    }
    link_to(signup_invites_share_path(:facebook, fb_ref: 'feed'), link_options, &block)
  end

  # FB FACEPILE INVITE CARD

  def fb_facepile_invite_card(card, options = {})
    mp_view_event('invite_card', source: 'feed', share_channel: 'facebook_request')
    container_options = {
      data: {
        message: t('facebook_facepile_invite_card.requests.message', inviter: card.viewer.name)
      }
    }
    excludes = card.viewer.u2u_invite_excludes
    container_options[:data][:exclude] = excludes.join(',') if excludes.any?
    invite_card_container(card, 'fb-facepile-invite', container_options) do
      out = []
      out << fb_facepile_invite_card_facepile(card)
      out << fb_facepile_invite_card_info(card)
      out << fb_facepile_invite_card_story(card)
      out << fb_facepile_invite_card_credits(card)
      out << fb_facepile_invite_card_actions(card)
      safe_join(out)
    end
  end


  # this is the old one with flipper action
  # freezing it for now
  def fb_facepile_invite_card_frozen(card, options = {})
    mp_view_event('invite_card', source: 'feed', share_channel: 'facebook_request')
    container_options = {
      data: {
        message: t('facebook_facepile_invite_card.requests.message', inviter: card.viewer.name)
      }
    }
    excludes = card.viewer.u2u_invite_excludes
    container_options[:data][:exclude] = excludes.join(',') if excludes.any?
    invite_card_container(card, 'fb-facepile-invite', container_options) do
      out = []
      out << fb_facepile_invite_card_story(card)
      out << fb_facepile_invite_card_flipper do
        out2 = []
        out2 << fb_facepile_invite_card_front(card)
#        out2 << fb_facepile_invite_card_back(card)
        safe_join(out2)
      end
      safe_join(out)
    end
  end

  def fb_facepile_invite_card_story(card)
    content_tag(:div, class: 'feed-container') do
      if card.story
        out = []
        out << content_tag(:div, '', class: 'avatar-container') do
          fb_facepile_invite_card_link('', class: 'avatar text-adjacent from-copious')
        end
        out << content_tag(:div, class: 'feed-story-container') do
          content_tag(:span, class: 'feed-story', data: {role: 'feed-story'}) do
            invite_link = fb_facepile_invite_card_link(t('facebook_facepile_invite_card.front.invite_link'))
            t('facebook_facepile_invite_card.front.story_html', invite_link: invite_link)
          end
        end
        safe_join(out)
      end
    end
  end

  def fb_facepile_invite_card_flipper(&block)
    data = {}
#    data[:flip] = 'card'
    content_tag(:div, class: 'flipper', data: data, &block)
  end

  def fb_facepile_invite_card_front(card)
    content_tag(:div, '', class: 'frontside') do
      out = []
      out << fb_facepile_invite_card_facepile(card)
      out << fb_facepile_invite_card_info(card)
      out << fb_facepile_invite_card_actions(card)
      safe_join(out)
     end
  end

  def fb_facepile_invite_card_facepile(card)
    content_tag(:div, '', class: 'product-image-container') do
      content_tag(:ul, class: 'waffle-format thumbnails') do
        out = []
        card.friend_profiles.each do |profile|
          out << content_tag(:li) do
            fb_facepile_invite_card_link do
              profile_avatar(profile, class: '', height: 75, width: 75)
            end
          end
        end
        if card.friend_count.present?
          out << content_tag(:li, class: 'more-link') do
            fb_facepile_invite_card_link do
              content_tag(:span, class: 'numbers') do
                t('facebook_facepile_invite_card.front.more', count: card.friend_count)
              end
            end
          end
        end
        safe_join(out)
      end
    end
  end

  def fb_facepile_invite_card_info(card)
    content_tag(:div, class: 'product-info') do
      fb_facepile_invite_card_link do
        out = []
        out << content_tag(:span, class: 'product-title') do
          t('facebook_facepile_invite_card.front.invite_title')
        end
        safe_join(out)
      end
    end
  end


  def fb_facepile_invite_card_story(card)
    content_tag(:div, class: 'social-story-container') do
      fb_facepile_invite_card_link do
        out = []
        out << content_tag(:span, class: 'social-story') do
          t('facebook_facepile_invite_card.front.invite_story',
            amount: smart_number_to_currency(Credit.amount_for_accepted_invite))
        end
        safe_join(out)
      end
    end
  end

  def fb_facepile_invite_card_credits(card)
    content_tag(:div, class: 'price-box') do
      fb_facepile_invite_card_link do
        out = []
        out << content_tag(:div, class: 'invite-credit-limit') do
          out2 = []
          out2 << tag(:hr)
          out2 << content_tag(:span, t('facebook_facepile_invite_card.front.invite_credit_limit',
            amount: smart_number_to_currency(Credit.max_inviter_credits_per_invitee)), class: 'invite-credit-limit')
          safe_join(out2)
        end
        safe_join(out)
      end
    end
  end

  def fb_facepile_invite_card_actions(card)
    content_tag(:div, class: 'product-action-area') do
      bootstrap_button(nilhref, toggle_modal: 'invite-friends', action_type: :social,
                       data: {action: 'fb-facepile-cta'}, size: :small) do
        out = []
        out << content_tag(:span, nil, class: 'icons-invite-fb')
        out << t('facebook_facepile_invite_card.front.button')
        safe_join(out)
      end
    end
  end

  def fb_facepile_invite_card_back(card)
    content_tag(:div, class: 'backside') do
      out = []
      out << fb_facepile_invite_card_back_content(card)
      out << fb_facepile_invite_card_back_info(card)
      out << fb_facepile_invite_card_back_actions(card)
      safe_join(out)
    end
  end

  def fb_facepile_invite_card_back_content(card)
    content_tag(:div, class: 'product-image-container white-gradient-bg') do
      out = []
      out << content_tag(:h3, t('facebook_facepile_invite_card.back.header'))
      out << content_tag(:span, t('facebook_facepile_invite_card.back.copy'), class: 'invite-title')
      out << content_tag(:div, class: 'invite-potential-credit-container') do
        out2 = []
        out2 << content_tag(:div, class: 'invite-potential-credit-amount-container') do
          content_tag(:span, class: 'invite-potential-credit-amount', data: {role: 'credit-amount'}) do
            smart_number_to_currency(0.00)
          end
        end
        safe_join(out2)
      end
      safe_join(out)
    end
  end

  def fb_facepile_invite_card_back_info(card)
    content_tag(:div, class: 'product-info') do
      fb_facepile_invite_card_link do
        content_tag(:span, t('facebook_facepile_invite_card.back.info_html'), class: 'invite-title')
      end
    end
  end

  def fb_facepile_invite_card_back_actions(card)
    content_tag(:div, class: 'production-action-area') do
      content_tag(:div, class: 'primary-button-container') do
        fb_facepile_invite_card_link do
          content_tag(:span, class: 'invite-button') do
            out = []
            out << content_tag(:span, nil, class: 'icon-invite-fb')
            out << t('facebook_facepile_invite_card.back.button')
            safe_join(out)
          end
        end
      end
    end
  end

  def fb_facepile_invite_card_link(*args, &block)
    options = args.extract_options!
    options[:data] ||= {}
    options[:data].merge!(action: 'fb-facepile-cta', toggle: :modal, target: '#invite-friends-modal')

    url = '#'
    if block_given?
      link_to(url, options, &block)
    else
      text = args.shift
      link_to(text, url, options)
    end
  end

  # SHARED

  def invite_card_container(card, card_type, options = {}, &block)
    li_classes = %w(card-container invite-card)# flip-animation)
    li_classes << 'logged_in' if logged_in?
    li_options = options.reverse_merge(class: class_attribute(li_classes))
    li_options[:data] ||= {}
    li_options[:data][:card] = card_type
    li_options[:data][:timestamp] = card.story.created_at.to_i if card.story
    li_options[:data][:source] = 'invite_card'
    content_tag(:li, li_options, &block)
  end
end
