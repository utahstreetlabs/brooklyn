module FollowHelper
  # Renders a follow control that wraps a follow button and provides the data elements needed for the follow button
  # to update follow counts elsewhere on the page. Intended to replace shared/follow and shared/follow_button partials
  #
  # @option options [String] :follower_count_selector (+#follower-count+) a CSS selector identifying page elements
  # containing follower counts that must be updated whenever the user is followed or unfollowed
  #
  # @see +#follow_button+
  def follow_control(followee, follower, options = {})
    options = options.dup
    follower_count_selector = options.delete(:follower_count_selector) || '#follower-count'
    data = {
      followee: followee.id,
      follower_count: follower_count_selector
    }
    source = options.delete(:source)
    data[:source] = source if source.present?
    content_tag(:span, class: 'follow-wrap', data: data) do
      follow_button(followee, follower, options)
    end
  end

  def follow_button(followee, follower, options = {})
    i18n_scope = [:follow_button, options[:text_for]].compact
    link_options = {action_type: :social}
    classes = options.fetch(:class, '').split(/\s+/)
    if follower == followee
      text = translate(:follow, scope: i18n_scope, name: followee.name)
      classes << 'disabled'
    else
      if !options[:force_follow].nil?
        following = false if options[:force_follow]
      elsif !options[:following].nil?
        following = options[:following]
      else
        following = follower.following?(followee)
      end
      if following
        method = :delete
        target = options.fetch(:unfollow_url, public_profile_unfollow_path(followee, text_for: options[:text_for]))
        action = 'unfollow'
        text = translate(:unfollow, scope: i18n_scope)
        classes += %w(do-unfollow actioned)
      else
        method = :put
        target = options.fetch(:follow_url, public_profile_follow_path(followee, text_for: options[:text_for]))
        action = 'follow'
        text = translate(:follow, scope: i18n_scope, name: followee.name)
        classes << 'do-follow'
      end
      classes << 'follow' # XXX: what is this for?
      link_options[:data] = {
        method: method,
        target: target,
        action: action,
        toggle: 'user-follow',
      }
    end
    text += " #{followee.firstname}" if options[:include_name]
    text = '' if options[:no_text]
    classes << 'no-text' if options[:no_text]
    link_options[:class] = class_attribute(classes)
    link_options[:type] = :button
    bootstrap_button(link_options) do
      out = []
      out << content_tag(:span, '', class: 'icons-button-follow')
      out << text
      safe_join(out)
    end
  end

  def block_button(blockee, blocker)
    classes = [:block, :left]
    if blocker.blocking? blockee
      method = :DELETE
      role = :unblock
      path = public_profile_unblock_path(blockee)
      text = ''
      classes << :blocked
    else
      method = :PUT
      role = :block
      path = public_profile_block_path(blockee)
      text = ''
    end
    link_to text, path, :class => classes.join(' '),
      data: {remote: true, method: method, type: :json, role: role, id: blockee.id }, rel: :nofollow
  end
end
