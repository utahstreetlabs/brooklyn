require 'network/base'

module Network
  class Twitter < Base
    def self.symbol
      :twitter
    end

    def self.copious_username
      self.config.corporate
    end

    def self.short_url_length
      20 # https://dev.twitter.com/docs/api/1/get/help/configuration - short_url_length_https
    end

    def self.max_tweet_length
      140
    end

    def self.max_screen_name_length
      20 # Alex Payne, 2009
    end

    def self.message_string_keys
      [:text]
    end

    def self.message_options!(message_key, params = {}, options = {})
      params[:copious] = "@#{copious_username}"
      params[:other_user_username] = "@#{options[:other_user_profile].username}" if options[:other_user_profile]
      mo = super(message_key, params, options)
      mo = fixup_share_message_options(params, options, mo) if message_key.to_s.starts_with?('share')
      mo
    end

    def self.message_string_scope(message, options = {})
      scope = super
      scope << (options[:other_user_profile] ? :other_user_on_network : :other_user_off_network)
      scope
    end

    def self.fixup_share_message_options(params, original_options, sharing_options)
      return sharing_options unless sharing_options[:text]

      # Listing sharing messages are of the form "%{variable} on %{copious} %{link}". The "fixed" parts of the
      # message must be preserved exactly as written. The variable part of the message must be truncated so that
      # the message fits into a single tweet.

      truncator = TweetTruncator.new(sharing_options[:text])
      truncator.match_fixed(' http.+')
      truncator.match_fixed(" on @#{Network::Twitter.copious_username}")

      # we aren't sure if we want to favor comment text over listing title and seller for tweets yet. for now we are
      # going to try favoring comment text. that means we truncate
      # "%{comment} about %{listing} by %{other_user_username}" instead of just the comment.

      truncator.match_fixed(" by @#{original_options[:other_user_profile].username}") if original_options[:other_user_profile]
      # Add this back in if we want to favor the listing
      # truncator.match(" about #{params[:listing]}") if params[:listing]

      sharing_options.merge(text: truncator.truncated)
    end

    def self.external_share_dialog_url(params={}, options={})
      # If we're passed in a set of related twitter ids, we could have more than one we need to
      # add to our redirection url
      related = Array.wrap(self.copious_username)
      related << options[:other_user_profile].username if options[:other_user_profile]
      related = related.compact.map {|u| URI.escape(u) }.join(',')
      target_url = "http://twitter.com/share?text=%s&related=%s&url=%s&counturl=%s" %
        [params[:text], related, params[:link], params[:link]]
    end

    # This truncator implements an algorithm that matches "fixed" parts of a tweet at the end of its text. Each time
    # +match_fixed+ is called, if the end of the variable part matches the specified pattern, the matched section is
    # removed from the variable part and prepended to the fixed part. When +truncated+ is called, the variable part
    # is truncated to fit into the space left over after the fixed part is accounted for, and the truncated variable
    # part is prepended to the fixed part to return the final truncated tweet text.
    class TweetTruncator
      def initialize(text)
        @variable = text
        @fixed = ''
        @max_truncatable_length = Network::Twitter.max_tweet_length
      end

      def match_fixed(pattern_string)
        re = eval "/^(.+)(#{pattern_string})$/"
        if @variable =~ re
          @variable = $1
          @fixed = "#{$2}#{@fixed}"
          @max_truncatable_length -= $2.mb_chars.length
        end
      end

      def truncated
        "#{@variable.truncate(@max_truncatable_length)}#{@fixed}"
      end
    end
  end
end
