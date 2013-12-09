module Network
  class Base
    include Brooklyn::Urls

    def self.config
      Network.config.send(self.symbol)
    end

    def self.app_id
      # all OAuth networks have an id
      self.config.app_id
    end

    def self.app_secret
      # all OAuth networks have a secret
      self.config.app_secret
    end

    def self.access_token
      # not all OAuth networks have an access token
      self.config.respond_to?(:access_token) ? self.config.access_token : nil
    end

    def self.omniauth_provider
      self.symbol
    end

    def self.to_sym
      self.symbol
    end

    def self.scope
      nil
    end

    def self.auth_callback_path(options = {})
      qs = []
      qs << "d=#{url_escape(options[:d])}" if options[:d]
      qs << "scope=#{options[:scope]}" if options[:scope]
      qs << "ot=#{options[:ot]}" if options[:ot] # origin type
      qs << (options.key?(:seller_signup) ? 's=s' : 's=b')
      path = "/auth/#{self.symbol}/callback"
      path << "?#{qs.join('&')}" if qs.any?
      path
    end

    def self.omniauth_options
      {}
    end

    def self.symbol
      raise NotImplementedError
    end

    def self.known?
      Network.known.include?(self.symbol)
    end

    def self.active?
      Network.active.include?(self.symbol)
    end

    def self.registerable?
      Network.registerable.include?(self.symbol)
    end

    def self.allow_feed_autoshare?(event)
      true
    end

    def self.allow_never_autoshare?
      config.respond_to?(:never_autoshare) ? self.config.never_autoshare : false
    end

    # Return the "secure" version of a network, if one exists.  For instagram,
    # this will return :instagram_secure.
    def self.as_secure
      nil
    end

    # Return it "insecure" version of a network, if one exists.  If this is an insecure network, returns its own
    # name.
    def self.as_insecure
      self.symbol
    end

    def self.secure?
      false
    end

    def self.canonical_name
      I18n.translate(:name, scope: [:networks, self.as_insecure])
    end

    def self.required_permissions
      self.config.respond_to?(:permissions) ? self.config.permissions.required : []
    end

    # Overridden by subclasses; allows us to render different informative messages
    # for a user after an auth failure dependent on scope.
    def self.auth_failure_message(options = {})
      nil
    end

    # Overridden by subclasses; allows us take different actions on failure
    # for different networks.
    def self.auth_failure_lambda(options = {})
      nil
    end

    def self.home_url
      self.config.url
    end

    def self.autoshare_events
      self.config.respond_to?(:autoshare) ? self.config.autoshare : []
    end

    def self.message_options!(message, params = {}, options = {})
      o = message_string_keys.inject({}) do |m, k|
        v = params[k] || message_string(message, k, params, options)
        m[k] = v if v.present?
        m
      end

      message_option_names.inject(o) do |m, k|
        v = params[k] || message_option(message, k)
        m[k] = v if v.present?
        m
      end
    end

    def self.message_string_keys
      []
    end

    def self.message_option_names
      []
    end

    def self.message_string_scope(message, options = {})
      [:feed_messages, message, self.symbol]
    end

    def self.message_string(message, key, params = {}, options = {})
      scope = message_string_scope(message, options)
      I18n.translate(key, params.merge(scope: scope, default: ''))
    end

    def self.message_option(message, name)
      return unless self.config.respond_to?(message)
      message_config = self.config.send(message)
      message_config.send(name) if message_config.respond_to?(name)
    end

    # Override in subclass to update network-specific preferences after profile updates.
    def self.update_preferences(user, options = {})
    end

    def self.has_permission?(scope, permission)
      return false unless scope.present?
      scope_array(scope).any? {|p| p.to_sym == permission.to_sym}
    end

    def self.default_scope?(scope)
      return true unless self.scope.present?
      scope.present? and (scope_array(self.scope) - scope_array(scope) == [])
    end

    protected

    def self.scope_array(scope)
      return [] unless scope.present?
      scope.split(%r{,\s*})
    end
  end
end
