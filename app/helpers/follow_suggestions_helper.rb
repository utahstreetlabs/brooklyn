module FollowSuggestionsHelper
  def follow_suggestions(suggestions, options={}, &b)
    options.merge!({class: 'ra-list', :'data-more' => follow_suggestions_path(blacklist: suggestions.map(&:id))})
    content_tag(:ul, options, &b)
  end

  def follow_suggestion(user, connection)
    content_tag(:li, :class => 'follow-suggestion ra-action') do
      link_to_delete_follow_suggestion(user.id) +
      user_avatar_small(user, :class => 'text-adjacent') +
      content_tag(:div, :class => 'follow-suggestion-text') do
        out = []
        out << link_to_user_profile(user, :class => 'follow-name')
        out << t('connections.summary.description', count: connection.shared_count) if connection
        out << capture { render 'shared/follow.html', user: user, force_follow: true }
        safe_join(out, ' ')
      end
    end
  end

  def link_to_delete_follow_suggestion(user_id)
    link_to image_tag('icons/close-content-hover.png'), follow_suggestion_path(user_id),
      remote: true, method: :DELETE, class: 'ra-remove remote-link', title: 'remove', :'data-id' => user_id
  end
end
