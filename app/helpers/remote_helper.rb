module RemoteHelper
  # Requires copious/remote_link JS library
  def remote_button(text, href, options = {})
    bootstrap_button(text, href, remote_control_options(options))
  end

  # Requires copious/remote_link JS library
  def remote_link(text, href, options = {})
    link_to(text, href, remote_control_options(options))
  end

  def remote_control_options(options = {})
    options = options.reverse_merge(rel: :nofollow, data: {})
    options[:data][:link] = :remote
    options[:data][:remote] = true
    options[:data][:method] ||= (options.delete(:method) || :post)
    options[:data][:refresh] ||= options.delete(:refresh)
    options[:data][:disable_with] ||= options.delete(:disable_with)
    options[:data][:type] = :json
    options
  end
end
