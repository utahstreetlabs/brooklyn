require 'active_support/concern'

module Brooklyn
  # A concern that provides methods for manipulating urls
  module Urls
    extend ActiveSupport::Concern

    module ClassMethods
      def url_escape(url)
        return url unless url
        URI.escape(url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      end

      def absolute_url(url, options={})
        return url if !url or url.start_with?('http')
        return "http:#{url}" if url.start_with?('//')
        "#{options[:root_url]}#{url}"
      end

      def as_query_string(params)
        params.map {|kv| "#{kv.first}=#{url_escape(kv.last)}"}.join('&')
      end
    end

    module InstanceMethods
      # make methods available on instance too for convenience
      def url_escape(url)
        self.class.url_escape(url)
      end

      def absolute_url(url, options={})
        self.class.absolute_url(url, options)
      end
    end
  end
end
