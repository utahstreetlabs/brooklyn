require 'network/base'

module Network
  class Facebook < Base
    include Brooklyn::Urls

    def self.omniauth_options
      {scope: self.scope}
    end

    def self.symbol
      :facebook
    end

    def self.open_graph_admins
      self.config.og.admins
    end

    def self.scope
      (self.config.permissions.required + self.config.permissions.optional).join(',')
    end

    def self.message_string_keys
      [:message, :caption, :name, :description]
    end

    def self.message_option_names
      [:picture, :link, :source, :type, :actions]
    end

    def self.notification_follow_group
      self.config.notification.follow.ref
    end

    def self.notification_like_group
      self.config.notification.like.ref
    end

    def self.notification_comment_group
      self.config.notification.comment.ref
    end

    def self.notification_batch_size
      self.config.notification.per
    end

    def self.notification_announce_group
      self.config.notification.announce.ref
    end

    def self.open_graph_post_delay
      self.config.og.post_delay_secs
    end

    def self.user_generated_images(listing, count)
      # 480px comes from the facebook documentation
      # http://developers.facebook.com/docs/opengraph/usergeneratedphotos/
      listing.photos.reject { |p| (h, w) = p.image_dimensions; h < 480 || w < 480 }.
        take(count).map {|p| absolute_url(p.file.url)}
    end

    def self.external_share_dialog_url(params={}, options={})
      app_id = URI.escape(self.app_id.to_s)
      url = "http://www.facebook.com/dialog/feed?app_id=%s&link=%s&name=%s&picture=%s&redirect_uri=%s&display=popup" %
        [app_id, params[:link], params[:text], params[:picture], params[:redirect]]
      url += "&description=#{params[:desc]}" if params[:desc]
      url += "&ref=#{params[:ref]}" if params[:ref]
      url += "&actions=#{params[:actions]}" if params[:actions]
      url
    end

    # Update user preferences, turning on timeline-related sharing if :publish_actions was provided.
    def self.update_preferences(user, options = {})
      # Disable this feature, which asks users if they want to
      # send posts automatically to the timeline.
      if has_permission?(options.fetch(:scope, nil), :publish_actions) &&
          user.allow_feature?(:request_timeline_facebook)
        user.save_features_disabled_prefs(request_timeline_facebook: '0')
        # The user's authentication request included the publish_actions permission,
        # so they've turned on timeline support.  We turn on all autosharing opt-ins,
        # (including those that really go to the Wall and not the timeline), when
        # this permission is enabled.
        autoshare_options = self.autoshare_events.each_with_object({}) { |e,m| m[e] = '1' }
        if autoshare_options.any?
          user.save_autoshare_prefs(self.symbol, autoshare_options)
          user.preferences.save_never_autoshare(false)
        end
      end
    end

    def self.auth_failure_message(options = {})
      scope = options.fetch(:scope, nil)
      if (scope && (scope.to_sym == :publish_actions))
        return :facebook_timeline
      end
    end

    def self.auth_failure_lambda(options = {})
      scope = options.fetch(:scope, nil)
      if (scope && (scope.to_sym == :publish_actions))
        return lambda do |user|
          # On an auth failure, when a user cancels adding publish_actions
          # to the app permissions, we set this preference so they're not
          # bugged with the timeline message box anymore
          return unless user.allow_feature?(:request_timeline_facebook)
          user.save_features_disabled_prefs(request_timeline_facebook: '0')
        end
      end
      nil
    end

    # For some events shared to Facebook we post directly to a user's wall
    # using traditional autosharing (via a profile's +post_to_feed+ method)
    # and for some we scheduled a delayed job that posts to a user's timeline (using
    # a profiles +post_to_ticker+ method).  We return false here for any event that
    # is posted to a user's timeline, because we're not posting to a feed in the traditional way.
    def self.allow_feed_autoshare?(event)
      self.config.respond_to?(:timeline_autoshare) ? !self.config.timeline_autoshare.include?(event) : false
    end

    # If we only requested timeline access and got a failure, we render a special
    # informative message for a user.
    def self.auth_failure_msg(scope)
      return :facebook_timeline if scope and scope.to_sym == :publish_actions
      nil
    end

    def self.with_real_b64_padding(digest)
      # thanks, facebook, for reading the specs
      missing = 4 - digest.length % 4
      if missing > 0 && missing < 4
        digest + '=' * missing
      else
        digest
      end
    end

    def self.valid_signature?(signature, payload)
      digest = OpenSSL::HMAC.digest('sha256', app_secret, payload)
      digest &&= Base64.urlsafe_encode64(digest)
      with_real_b64_padding(signature) == digest
    end

    # there's something very similar in omniauth, anyone who can figure out how to get access to the strategy from
    # here can feel free to change it
    def self.parse_signed_request(data)
      signature, payload = data.split('.', 2)
      if valid_signature?(signature, payload)
        decoded = Base64.urlsafe_decode64(with_real_b64_padding(payload))
        decoded && Hashie::Mash.new(ActiveSupport::JSON.decode(decoded))
      end
    end

    def self.message_options!(message, params = {}, options = {})
      options = add_additional_message_options(message, super, params)
      options[:actions] = options[:actions].to_json if options[:actions]
      options
    end

    def self.add_additional_message_options(message, message_options, params = {})
      options = case message
      when :invite_with_credit
        {
          actions: [{name: feed_message_t(message, :action_name, name: params[:firstname]), link: params[:link]}],
          ref: Network::Facebook::Ref.new(:inviteds2).to_ref
        }
      when :signup
        {
          actions: [{name: feed_message_t(message, :action_name, name: params[:firstname]), link: params[:link]}],
          ref: Network::Facebook::Ref.new(:join2).to_ref
        }
      else
        {}
      end

      message_options.reverse_merge(options)
    end

    def self.feed_message_t(message, key, options)
      options[:scope] ||= "feed_messages.#{message}.facebook"
      I18n.translate(key, options)
    end

    def self.uids_to_exclude_from_u2u_invites(inviter)
      exclude_since = self.config.u2u_invites.exclude_invited_since
      if exclude_since
        FacebookU2uInvite.find_all_fb_user_ids_pending_since(exclude_since, sender: inviter)
      else
        []
      end
    end
  end
end
