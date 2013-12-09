module UsersHelper
  def link_to_user_profile(user, options = {}, &block)
    text = block_given?? capture { block.call } : options.delete(:text)
    text ||= user.name
    if user.inactive?
      content_tag :span, text, class: 'inactive-user'
    elsif user.guest?
      logged_in? and current_user == user ? 'you' : 'guest user'
    elsif user.registered?
      url = options.delete(:url) || public_profile_path(user)
      link_to text, url, options
    else
      text
    end
  end

  # Given a set of users, transform the user names such that the result is
  # "User A, User B, and User C" or "User A and User B" if necessary.
  # By default wrap as a link.  For the current user, we substitute "You"
  # and make sure that "You" is always the first in the list.
  #
  # Options:
  # +summarize_after+ (Integer): returned string is summarized after N values; e.g. for N=2
  #  "User A, User B, and 4 others"
  # +current_user_first+ (Boolean): returned string is sorted so that the current user is first; e.g.
  #  "You, User A, and User B"
  # +sort_alpha+ (Boolean): sort the users by name, alphabetically
  # +translate_current_user+: replace the current user by the translation by "You" (in english)
  def aggregate_user_profile_names(users, options = {})
    # Store away options.
    summarize_after = options.delete(:summarize_after)
    sort_alpha = options.delete(:sort_alpha)
    translate_current_user = options.delete(:translate_current_user)
    current_user_first = options.delete(:current_user_first)
    name_only = options.delete(:name_only)

    # If we want to sort alphabetically and put the current user first, this
    # occurs in a single sort.
    if current_user_first || sort_alpha
      users = users.sort do |x,y|
        if current_user_first
          if x.name == current_user.name
            -1
          elsif y.name == current_user.name
            1
          else
            sort_alpha ? x.name <=> y.name : 0
          end
        else
          # We want to sort alphabetically, but don't care about the current user placement
          x.name <=> y.name
        end
      end
    end
    ret = users.map do |u|
      if translate_current_user && logged_in? && current_user == u
        name_only ? I18n.t('helpers.users.current_user') : link_to_user_profile(u, options.merge(text: I18n.t('helpers.users.current_user')))
      else
        name_only ? u.name : link_to_user_profile(u, options)
      end
    end
    # We don't summarize unless there's at least one user to summarize
    if summarize_after
      summarize_count = ret.count - summarize_after
      if summarize_count > 0
        ret = ret.shift(summarize_after)
        ret << "#{summarize_count} #{(summarize_count == 1 ? "other" : "others")}"
      end
    end
    ret.to_sentence.html_safe
  end

  def user_profile_photo_url(user, width, height)
    if user.guest?
      "#{ProfilePhotoUploader.default_file_path}/px_#{width}x#{height}_#{ProfilePhotoUploader.default_file_name}"
    else
      user.profile_photo.url(:"px_#{width}x#{height}")
    end
  end

  def user_avatar(user, width, height, options = {})
    options = options.reverse_merge(height: height, width: width, alt: '', title: user.name)
    src = options.delete(:src) || user_profile_photo_url(user, width, height)
    image_tag(src, options)
  end

  def user_avatar_xsmall(user, options = {})
    img_options = {class: 'avatar-small'}.merge(options.delete(:img) || {})
    img = user_avatar(user, 30, 30, img_options)
    link_user_avatar(img, user, options)
  end

  def user_avatar_xsmall_nolink(user, options = {})
    content_tag(:span, :class => 'avatar') do
      img_options = {class: 'avatar-small'}.merge(options.delete(:img) || {})
      img = user_avatar(user, 30, 30, img_options)
    end
  end

  def user_avatar_small(user, options = {})
    img = user_avatar(user, 50, 50, (options.delete(:img) || {}))
    link_user_avatar(img, user, options)
  end

  def user_avatar_medium(user, options = {})
    img = user_avatar(user, 70, 70, (options.delete(:img) || {}))
    link_user_avatar(img, user, options)
  end

  def user_avatar_large(user, options = {})
    img = user_avatar(user, 150, 150, (options.delete(:img) || {}))
    link_user_avatar(img, user, options)
  end

  def user_avatar_xlarge(user, options = {})
    img = user_avatar(user, 190, 190, (options.delete(:img) || {}))
    link_user_avatar(img, user, options)
  end

  def user_profile_canonical_photo_url(user)
    user_profile_photo_url(user, 190, 190)
  end

  def link_user_avatar(img, user, options = {})
    return img if user.inactive? || user.guest? || user.connected?
    url = options.delete(:url) || public_profile_path(user)
    klass = (options[:class] || '') + ' avatar'
    options = options.merge({class: klass})
    link_to img, url, options
  end
end
