# in fact, almost all of these helpers are DEPRECATED, since connection is presented much differently on the listing
# page than it is in the product card. those helpers which are still used by the listing page should be moved to
# ListingsHelper, and the others should be deleted once the product card feature has shipped.
module ConnectionHelper
  def connection_image_tag(connection_or_signal, options = {})
    large = options.delete(:large) || false
    signal = connection_or_signal.is_a?(SocialConnection) ? connection_or_signal.signal : connection_or_signal
    image_name = "#{options[:image_name] || 'connection_strength_v3'}_"
    image_name += 'large_' if large
    image_name += signal.to_s
    css_class = large ? 'connection-large' : 'connection'
    image_tag("icons/#{image_name}.png", :class => css_class)
  end

  def connection_signal_image_tag(connection)
    signal = connection ? connection.signal : 0
    image_tag("icons/connection_signal_#{signal}.png", alt: "Connection signal #{signal}")
  end

  # viewer is the user current viewing the listing
  def summary_connection(listing, viewer, connection)
    if (listing.sold_by?(viewer))
      connection_text = t(:description_self, :scope => [:connections, :summary])
      signal = 5
    else
      signal = connection.signal
      count = connection.path_count
      connection_text = t(:description, :scope => [:connections, :summary], :count => count)
    end
    out = []
    out << connection_image_tag(signal)
    out << content_tag(:span, t(:listed_by, :scope => [:connections, :summary],
      :seller => link_to_user_profile(listing.seller)).html_safe, :class => 'name')
    out << content_tag(:span, connection_text, :class => 'connections')
    out.join().html_safe
  end

  def connection_path_list_item(path, options = {})
    avatar_options = options.fetch(:avatar, {})
    content_tag(:li) do
      # if the path isn't direct, we never use the first hop as part of the description
      # since the above key approach will create collisions, we break the keys out into direct and indirect
      subtype = path.direct?? :direct : :indirect
      key = (path.direct?? path.types : path.types[1..-1]).join('_').to_sym
      out = []
      out << person_avatar_small(path.adjacent, avatar_options.dup)
      out << t(key, :scope => [:connections, :types, subtype], :other => link_to_person_profile(path.other),
        :adjacent => link_to_person_profile(path.adjacent))
      out.join().html_safe
    end
  end

  def detail_heading(other, connection)
    out = []
    out << t(:title, :scope => [:connections, :detail], :other => other.firstname)
    out << connection_tooltip
    out << connection_image_tag(connection)
    out.join().html_safe
  end

  def detailed_connection(other, connection, limit)
    unless connection.nil?
      out = []
      out << connection_list(connection, limit)
      out.join().html_safe
    end
  end

  def connection_list(connection, limit, options = {})
    content_tag(:ul, :class => 'avatar-list') do
      connection.paths[0...limit].inject(''.html_safe) { |out, path| out << connection_path_list_item(path, options) }
    end
  end

  def connection_tooltip
    qmark_tooltip t(:tooltip, :scope => [:connections])
  end

  def number_to_connection_signal(count)
    count ? (number_to_human count, format: '%n%u', units: :connection_signal) : '?'
  end
end
