module HomeHelper
  def thumbnail_wall
    num_to_show = 72
    num_images = 35
    row_size = 6
    current_img = 1
    out = []
    1.upto(num_to_show).each do |n|
      img_options = {}
      img_options[:class] = 'last' if n % row_size == 0
      out << image_tag("landing/stock_products/#{current_img}.jpg", img_options)
      current_img = current_img == num_images ? 1 : current_img + 1
    end
    out.join("\n").html_safe
  end

  def new_in_your_network(stories, following)
    content_tag(:ul, class: 'network-list') do
      stories.inject(''.html_safe) do |m, story|
        details = new_in_network_details(story, following: following)
        if details && details.length > 0
          m << content_tag(:li, class: 'network-story') do
            details + content_tag(:span, "#{time_ago_in_words(story.created_at)} ago", class: 'time-stamp')
          end
        end
        m
      end
    end
  end

  def new_in_network_details(story, options = {})
    actor = story.actor
    case story.type
    when :user_followed
      new_in_network_follow_story(story.actor, story.followee, options)
    when :user_joined
      new_in_network_joined_story(story.actor, options)
    when :user_invited
      new_in_network_invited_story(story.actor, story.invitee, options)
    when :user_piled_on
      new_in_network_invited_story(story.actor, story.invitee, options)
    else
      Rails.logger.warn("Unsupported story type #{story.type}")
      ''
    end
  end

  def new_in_network_follow_story(follower, followee, options)
    content_tag(:div, class: 'network-avatar-container') do
      if followee == current_user
        content_tag(:div, user_avatar_small(follower), class: 'avatar-container single')
      else
        content_tag(:div, user_avatar_xsmall(follower), class: 'avatar-container follower-avatar') +
        content_tag(:div, user_avatar_small(followee), class: 'avatar-container followee-avatar')
      end
    end +
    content_tag(:div, class: 'network-story-text') do
      out = []
      out << link_to_user_profile(follower)
      if followee == current_user
        out << 'is now following you'
        out << content_tag(:div,
    new_in_network_follow_button(follower, options[:following]), class: 'follow-wrap follow-back')
      else
        out << 'is now following'
        out << link_to_user_profile(followee)
        out << content_tag(:div,
    new_in_network_follow_button(followee, options[:following]), class: 'follow-wrap follow-back')
      end
      out.join(' ').html_safe
    end
  end

  def new_in_network_invited_story(inviter, invitee, options)
    content_tag(:div, class: 'network-avatar-container') do
      content_tag(:div, user_avatar_xsmall(inviter), class: 'avatar-container inviter-avatar') +
      content_tag(:div, link_to_profile_avatar(invitee), class: 'avatar-container invitee-avatar')
    end +
    content_tag(:div, class: 'network-story-text') do
      out = []
      out << link_to_user_profile(inviter)
      out << 'invited'
      out << link_to_network_profile(invitee)
      out.join(' ').html_safe
    end
  end

  def new_in_network_joined_story(joiner, options = {})
    content_tag(:div, class: 'network-avatar-container') do
      content_tag(:div, user_avatar_small(joiner), class: 'avatar-container single')
    end +
    content_tag(:div, class: 'network-story-text') do
      out = []
      out << link_to_user_profile(joiner)
      out << 'joined Copious'
      out << content_tag(:div, new_in_network_follow_button(joiner, options[:following]), class: 'follow-wrap follow-back')
      out.join(' ').html_safe
    end
  end

  def new_in_network_follow_button(followee, following = {})
    unless following[followee.id]
      follow_button followee, current_user, include_name: true, force_follow: true, class: 'small'
    end
  end

  def feed_link(feed, selected)
    content = content_tag(:li, translate(feed, scope: 'home.logged_in.feed'), :class => (feed == selected ? 'selected' : ''))
    return content if feed == selected
    content_tag(:li, :class => (feed == selected ? 'selected' : '')) do
      link_to(translate(feed, scope: 'home.logged_in.feed'), root_path(feed: feed))
    end
  end

  def feed_selector(selected)
    content_tag(:div, class: 'nav-container hero') do
      content_tag :ul, :class => 'nav-tabs copious-tabs' do
        feeds = []
        feeds << feed_link(:network, selected)
        feeds << feed_link(:everything, selected)
        feeds.join.html_safe
      end
    end
  end

  def signup_credit_cta
    controller.class.with_error_handling('assigned signup credit experimental group') do
      version = ab_test(:signup_credit)
      if signup_offer
        amount = signup_offer.amount
        min_purchase = signup_offer.minimum_purchase
        content_tag :p, class: 'signup_credit_copy hidden-phone' do
          t(:signup_credit_cta, amount: smart_number_to_currency(amount), min_purchase: smart_number_to_currency(min_purchase), scope: 'helpers.home').html_safe
        end
      end
    end
  end

  def home_banner(options = {})
    promo_banner(Brooklyn::Application.config.banners.home, options)
  end

  def home_user_header(options = {})
    classes = 'home-user-container'
    classes << ' new-user' if current_user.just_registered?
    content_tag(:div, class: classes) do
      content_tag(:div, class: 'home-header') do
        out = []
        if current_user.just_registered?
          out << content_tag(:h1, t('shared.welcome_headers.home.logged_in.new.welcome_title'), class: 'hero')
          out << content_tag(:h2, t('shared.welcome_headers.home.logged_in.new.title'))
          out << content_tag(:ul, class: 'new-user-activities') do
            out2 = []
            out2 << content_tag(:li, class: 'new-user-discover') do
              out3 = []
              out3 << content_tag(:h3, t('shared.welcome_headers.home.logged_in.new.discover_title'))
              out3 << t('shared.welcome_headers.home.logged_in.new.discover_description')
              safe_join(out3)
            end
            out2 << content_tag(:li, class: 'new-user-organize') do
              out3 = []
              out3 << content_tag(:h3, t('shared.welcome_headers.home.logged_in.new.organize_title'))
              out3 << t('shared.welcome_headers.home.logged_in.new.organize_description')
              safe_join(out3)
            end
            out2 << content_tag(:li, t('shared.welcome_headers.home.logged_in.new.title'), class: 'new-user-list') do
              out3 = []
              out3 << content_tag(:h3, t('shared.welcome_headers.home.logged_in.new.list_title'))
              out3 << t('shared.welcome_headers.home.logged_in.new.list_description')
              safe_join(out3)
            end
            safe_join(out2)
          end
        else
          out << content_tag(:h1) do
            out2 = []
            out2 << t('shared.welcome_headers.home.logged_in.existing.welcome_title', name: current_user.firstname)
            safe_join(out2)
          end
          out << content_tag(:p, t('shared.welcome_headers.home.logged_in.existing.welcome_description_html'))
        end
        safe_join(out)
      end
    end
  end

  def logged_out_header(options = {})
    classes = 'home-user-container logged-out-header'
    content_tag(:div, class: classes) do
      content_tag(:div, class: 'home-header') do
        out = []
        out << content_tag(:h1, t('shared.welcome_headers.trending.logged_out.title'), class: 'hero')
        out << content_tag(:ul, class: 'new-user-activities') do
          out2 = []
          out2 << content_tag(:li, class: 'new-user-discover') do
            out3 = []
            out3 << content_tag(:h3, t('shared.welcome_headers.home.logged_in.new.discover_title'))
            out3 << t('shared.welcome_headers.home.logged_in.new.discover_description')
            safe_join(out3)
          end
          out2 << content_tag(:li, class: 'new-user-organize') do
            out3 = []
            out3 << content_tag(:h3, t('shared.welcome_headers.home.logged_in.new.organize_title'))
            out3 << t('shared.welcome_headers.home.logged_in.new.organize_description')
            safe_join(out3)
          end
          out2 << content_tag(:li, t('shared.welcome_headers.home.logged_in.new.title'), class: 'new-user-list') do
            out3 = []
            out3 << content_tag(:h3, t('shared.welcome_headers.home.logged_in.new.list_title'))
            out3 << t('shared.welcome_headers.home.logged_in.new.list_description')
            safe_join(out3)
          end
          safe_join(out2)
        end
        out << content_tag(:div, class: 'connect-container') do
          out4 = []
          out4 << link_to_facebook_connect(class: 'signup button xlarge facebook')
          unless feature_enabled?('signup.entry_point.fb_oauth_dialog') &&
                 ab_test(:signup_entry_point).in?(([:fb_oauth_dialog_1, :fb_oauth_dialog_2]))
            out4 << link_to_twitter_connect(class: 'button xlarge twitter')
          end
          safe_join(out4)
        end
        safe_join(out)
      end
    end
  end

  def home_messaging
    out = top_messages.map do |message|
      content_tag(:div, class: 'row') do
        content_tag(:div, data: {role: 'top-message', key: message.key}, class: 'top-message') do
          out2 = []
          out2 << content_tag(:h3, message.header) if message.header.present?
          out2 << raw(message.text)
          safe_join(out2)
        end
      end
    end
    safe_join(out)
  end

  def home_collection_carousel(carousel)
    out = []
    out << content_tag(:h1, class: 'section-title carousel-title') do
      t('home.logged_in.recommended.section_title')
    end
    # a null interval tells Bootstrap to not auto-cycle the groups
    out << content_tag(:div, id: 'collection-carousel', class: 'carousel slide', data: {interval: ''}) do
      out2 = []
      out2 << content_tag(:div, class: 'carousel-inner') do
        out3 = carousel.each_group.each_with_index.map do |cards, index|
          classes = %w(item)
          # .active denotes the currently visible group
          classes << 'active' if index == 0
          content_tag(:div, class: class_attribute(classes)) do
            safe_join(cards.map { |card| collection_card(card) })
          end
        end
        safe_join(out3)
      end
      if carousel.group_count > 1
        out2 << link_to(raw('&lsaquo;'), '#collection-carousel', class: 'carousel-control left', data: {slide: 'prev'})
        out2 << link_to(raw('&rsaquo;'), '#collection-carousel', class: 'carousel-control right', data: {slide: 'next'})
      end
      safe_join(out2)
    end
    safe_join(out)
  end
end
