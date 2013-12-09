require 'datagrid'

class FeatureFlag < ActiveRecord::Base
  attr_accessible :enabled, :admin_enabled
  default_sort_column :name
  search_columns :name, :description

  cattr_accessor :admin
  @@admin = false

  def self.admin?
    !!admin
  end

  def self.enabled?(*scopes)
    ThreadLocalFlagCache.enabled?(*scopes)
  end

  def self.setup(options = {})
    FeatureFlag.admin = !!options[:admin]
  end

  def self.flush_cache
    ThreadLocalFlagCache.flush
  end

  class ThreadLocalFlagCache
    THREAD_KEY = self.class.name

    def initialize
      if FeatureFlag.admin?
        column = :admin_enabled
        method = :admin_enabled?
      else
        column = :enabled
        method = :enabled?
      end
      @index = FeatureFlag.select([:name, column]).each_with_object({}) { |flag, m| m[flag.name] = flag.send(method) }
    end

    def exists?(name)
      @index.key?(name)
    end

    def enabled?(name)
      if exists?(name)
        @index[name]
      else
        Rails.logger.error("Feature flag #{name} not configured")
        false
      end
    end

    def self.enabled?(*scopes)
      name = scopes.join('.')
      cache = (Thread.current[THREAD_KEY] ||= ThreadLocalFlagCache.new)
      if cache
        cache.enabled?(name)
      else
        flag = FeatureFlag.find_by_name(name)
        flag ? flag.enabled? : false
      end
    end

    def self.flush
      Thread.current[THREAD_KEY] = nil
    end
  end
end
