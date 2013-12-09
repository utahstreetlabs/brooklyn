require 'active_support/concern'

module Users
  # User API for automatically sharing to external network feeds in response to system events (e.g. listing activated,
  # user followed). The user can set preferences to govern autosharing for each combination of network and event.
  module AutoShareable
    extend ActiveSupport::Concern

    module InstanceMethods
      # Returns whether or not the user allows autoshares for +event+ to +network+.
      def allow_autoshare?(event, network, options = {})
        prefs = options[:preferences] || preferences
        prefs.allow_autoshare?(network, event) && !prefs.never_autoshare
      end

      #  Shares an event for each network that the user allows that event to be autoposted.
      def autoshare(event, *args)
        person.connected_networks.each do |network|
          if allow_autoshare?(event, network) && Network.klass(network).allow_feed_autoshare?(event)
            person.send("share_#{event}".to_sym, network, *args)
          end
        end
      end

      # Saves autoshare preferences for a network. +params+ is a hash with keys as the name of the pref and value of 1
      # as setting on and 0 as setting out. +event is an array of all the keys that are set to on.
      def save_autoshare_prefs(network, params)
        events = params.select {|k,v| v == '1'}.keys
        rv = preferences.save_autoshare_opt_ins(network, events)
        if rv
          @preferences = rv
          true
        else
          false
        end
      end
    end
  end
end
