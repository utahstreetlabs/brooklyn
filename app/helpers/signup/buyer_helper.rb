module Signup
  module BuyerHelper
    FLOW_STEPS = [
      I18n.t("shared.profile_form.profile"),
      I18n.t("shared.profile_form.interests"),
      I18n.t("shared.profile_form.people")
    ]

    def signup_buyer_flow_step(step)
      @signup_buyer_flow_step = step
    end

    def signup_buyer_interest_like_control(interest_cards, options = {})
      counter_class = 'likes-counter'
      button_class = 'likes-counter-button button primary clear large'
      if interest_cards.liked.count >= Interest.num_required_for_signup
        counter_class << ' done'
        likes_needed = 0
      else
        button_class << ' disabled'
        likes_needed = Interest.num_required_for_signup - interest_cards.liked.count
      end
      container_class = 'like-button-container'
      container_class << " #{options[:class]}" if options[:class]
      content_tag :div, class: container_class, data: {count: interest_cards.liked.count, required: Interest.num_required_for_signup} do
        link_to('Continue', complete_signup_buyer_interests_path, method: :POST, class: button_class) +
        content_tag(:div, class: counter_class) do
          content_tag(:span, likes_needed, class: 'likes-counter-count strong') +
          ' more to go' + content_tag(:div, nil, class: 'likes-arrow')
        end
      end
    end

    def signup_buyer_follow_suggestions(follow_suggestions, viewer, options)
      content_tag(:ul, id: 'invite-friends-list') do
        s = []
        follow_suggestions.each do |user, profile|
          s << content_tag(:li, data: {role: 'selectable', type: 'follow'}) do
            out = []
            out << content_tag(:div, class: 'avatar-container') do
              profile_avatar(profile)
            end
            out << content_tag(:div, class: 'invitee-name-container') do
              content_tag(:div, profile.name, class: 'invitee-name')
            end
            out << check_box_tag(user.id)
            safe_join(out)
          end
        end

        options[:invite_suggestions].each do |profile|
          s << content_tag(:li, data: {role: 'selectable', type: 'invite'}) do
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

    def signup_buyer_complete_button(options = {})
      button_class = 'button large pull-right primary complete'
      button_class << " #{options[:class]}" if options[:class]
      link_to 'Continue', complete_signup_buyer_people_path, method: :POST, class: button_class
    end

    def signup_buyer_follow_button(options = {})
      button_class = %w(button large pull-right primary complete)
      button_class << "#{options[:class]}" if options[:class]
      link_to 'Continue', complete_signup_buyer_friends_path, method: :POST, class: class_attribute(button_class), id: 'continue-button'
    end
  end
end
