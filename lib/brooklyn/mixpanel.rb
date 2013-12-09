require 'active_support'
require 'ga_cookie_parser'
require 'typhoeus'
require 'user_agent'

module Brooklyn
  module Mixpanel
    include Ladon::Logging
    mattr_accessor :token
    @@token = nil

    # set to true to have event pushed through with high priority.
    # NB: events submitted with this flag are throttled and will actually be *dropped* if over the limit.
    # so use only for dev / test
    mattr_accessor :test_mode
    @@test_mode = false

    mattr_accessor :base_url
    @@base_url = 'http://api.mixpanel.com'

    @@paths = {track: 'track', engage: 'engage'}

    def self.url(action)
      "#{@@base_url}/#{@@paths[action]}" + (@@test_mode ? '?test=1' : '')
    end

    def self.post(action, params)
      data = ActiveSupport::Base64.encode64s(JSON.generate(params))
      response = Typhoeus::Request.post(url(action), :params => {data: data})
      raise "mixpanel request failed with status #{response.code} body #{response.body}" unless
        response.code == 200 && response.body == '1'
      true
    end

    # Track events in mixpanel
    #
    # Events can be identified by setting either distinct_id (mixpanel's terminology) or
    # visitor_id (our terminology). If both are set, distinct_id will be used.
    #
    # https://mixpanel.com/docs/api-documentation/http-specification-insert-data
    #
    def self.track(event, properties = {})
      raise "no mixpanel token configured" unless @@token
      # delete visitor_id whether or not distinct_id is set so that we don't send it to mixpanel
      visitor_id = properties.delete(:visitor_id)
      properties[:distinct_id] ||= visitor_id
      properties[:token] = @@token
      params = {event: event, properties: merge_special_properties(merge_global_properties(properties))}
      logger.debug("Tracking event #{event} with properties #{params}")
      post(:track, params)
    end

    def self.merge_global_properties(properties)
      if properties[:mp_cookies]
        super_properties = properties.delete(:mp_cookies).map do |k, value|
          begin ActiveSupport::JSON.decode(value).symbolize_keys rescue {} end
        end.find {|v| v[:distinct_id] == properties[:distinct_id]}
        (super_properties || {}).merge(properties)
      else
        properties
      end
    end

    def self.merge_special_properties(properties)
      merge_fb_ref_properties(merge_utm_properties(merge_user_agent_properties(merge_referrer_properties(properties))))
    end

    def self.referring_domain(referrer)
      begin
        URI.parse(referrer).host
      rescue URI::InvalidURIError => e
        logger.error("failed to parse #{referrer} for a domain")
        nil
      end
    end

    def self.merge_referrer_properties(properties)
      referrer = properties.delete(:referrer)
      if referrer
        properties.merge(:'$referrer' => referrer, :'$referring_domain' => referring_domain(referrer))
      else
        properties
      end
    end

    def self.merge_user_agent_properties(properties)
      user_agent = properties.delete(:user_agent)
      if user_agent
        ua = ::UserAgent.parse(user_agent)
        properties.merge(:'$os' => ua.os, :'$browser' => ua.browser)
      else
        properties
      end
    end

    def self.merge_utm_properties(properties)
      utm_query_params = properties.delete(:utm_query_params)
      properties.merge!(utm_query_params.reject {|_, v| v.nil?}) if utm_query_params
      properties
    end

    def self.fb_ref_params(fb_ref)
      begin
        ref = Network::Facebook::Ref.from_ref(fb_ref)
        {fb_types: ref.insights_tags}.merge(Hash[*ref.data.map { |key, value|  [:"fb_#{key}", value] }.flatten])
      rescue Exception => e
        logger.error("Could not parse fb_ref #{fb_ref}: #{e}")
        {}
      end
    end

    def self.merge_fb_ref_properties(properties)
      fb_ref = properties.delete(:fb_ref)
      if fb_ref
        properties.merge(fb_ref_params(fb_ref))
      else
        properties
      end
    end

    # Post to the mixpanel engagement API
    #
    # https://mixpanel.com/docs/people-analytics/people-http-specification-insert-data
    #
    def self.engage(id, properties)
      self.post(:engage, {:'$distinct_id' => id, :'$token' => @@token}.merge(properties))
    end

    # Set user properties in mixpanel
    #
    def self.set(id, user_properties)
      self.engage(id, :'$set' => user_properties)
    end

    # Increment a mixpanel property for a user
    #
    # Can be called with a single property name like:
    #
    # increment('12345', 'total sales')
    #
    # of a hash of attribute names and increments like:
    #
    # increment('12345', {'total sales' => 1, 'credits' => 40})
    #
    def self.increment(id, increments)
      increments = {increments => 1} if increments.is_a? String
      self.engage(id, :'$add' => increments)
    end
  end
end
