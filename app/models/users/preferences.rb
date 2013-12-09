require 'active_support/concern'
require 'lagunitas/models/preferences'

module Users
  module Preferences
    extend ActiveSupport::Concern

    def preferences
      unless @preferences
        logger.debug("Finding preferences for user #{id}")
        @preferences = Lagunitas::Preferences.find(id)
      end
      @preferences
    end

    # Returns the preferences of the user's followers as a hash of +Lagunitas::Preferences+ keyed by user id. Note that
    # these preferences are not memoized.
    def follower_preferences(options = {})
      self.class.preferences(followers, options)
    end

    def email_prefs
      preferences.emails
    end

    # Saves the new state of the user's email opt-out prefs. +params+ is a hash of check box params (either +'1'+ or
    # +'0'+) keyed by email name. Ex: {'follow_me' => '0'}. Each +'1'+ indicates the removal of an opt-out for that
    # email; all other emails have opt-outs added for them. Returns true if the prefs were successfully updated, false
    # otherwise.
    def save_email_prefs(params)
      params = params.each_with_object({}) {|(k,v),m| m[k] = (v != '1')}
      logger.debug("Saving email preferences #{params}")
      rv = preferences.save_email_opt_outs(params)
      if rv
        @preferences = rv
        true
      else
        false
      end
    end

    # Returns whether or not the user opts in to the named email. Recognizes the following options:
    #
    # +preferences+: uses the provided +Preferences+ rather than the one internal to the user instance (useful when
    # prefs for a number of users were fetched en masse)
    def allow_email?(key, options = {})
      # don't use options.fetch(:preferences, preferences) as we only want preferences to be evaluated if the option
      # was not provided
      prefs = options[:preferences] || preferences
      prefs.allow_email?(key)
    end

    # Saves the new state of the user's disable feature option prefs.
    #
    # @param [Hash] params a hash of check box params (either +'0'+ or +'1'+) keyed by feature name.
    # The values in the hash represent *opt-in*.  For example: {'request_timeline_facebook' => '0'} will turn off
    # the +:request_timeline_facebook+ feature.
    # @return [Boolean] whether or not the prefs were succesfully saved
    def save_features_disabled_prefs(params)
      params = params.each_with_object({}) {|(k,v),m| m[k] = (v != '1')}
      logger.debug("Saving disabled feature preferences #{params}")
      rv = preferences.save_features_disabled(params)
      if rv
        @preferences = rv
        true
      else
        false
      end
    end

    # Returns whether or not the user opts in to the named feature. Recognizes the following options:
    #
    # +preferences+: uses the provided +Preferences+ rather than the one internal to the user instance (useful when
    # prefs for a number of users were fetched en masse)
    def allow_feature?(key, options = {})
      # Fall back on using preferences; don't use options.fetch(:preferences, preferences)
      # as we only want preferences to be evaluated if the option was not provided
      prefs = options[:preferences] || preferences
      !prefs.features_disabled.include?(key.to_s)
    end

    def privacy_prefs
      preferences.privacy
    end

    # Saves the provided privacy preferences, overwriting any existing ones.
    #
    # @param [Hash(Symbol => Boolean)] prefs the privacy value for each pref (true when private, false when public)
    # @return [Boolean] whether or not the prefs were succesfully saved
    # @see Lagunitas::Preferences#save_privacy
    def save_privacy_prefs(prefs)
      logger.debug("Saving privacy preferences #{prefs}")
      new_prefs = Lagunitas::Preferences.new(user_id: self.id).save_privacy(prefs)
      if new_prefs
        @preferences = new_prefs
        true
      else
        false
      end
    end

    # @option options [Lagunitas::Preferences] :preferences
    # @return [Boolean] whether or not the indicated preference is private or not
    # @see Lagunitas::Preferences#private?
    def private?(key, options = {})
      prefs = options[:preferences] || preferences
      prefs.private?(key)
    end

    module ClassMethods
      # Returns a hash of +Lagunitas::Preferences+ keyed by user id.
      def preferences(users, options = {})
        user_ids = users.map(&:id)
        logger.debug "Finding preferences for users #{user_ids}"
        Lagunitas::Preferences.find(users.map(&:id))
      end
    end
  end
end
