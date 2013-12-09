class Value
  attr_accessor :value
  @value = nil
  def expire(ttl); end
end

class Stash
  attr_reader :hash
  delegate :[], to: :hash

  def initialize
    @hash = {}
  end

  def []=(key, value)
    self.hash[key] = value.to_s
  end
end

class StashingUser
  attr_reader :stash
  attr_accessor :id, :last_feed_refresh

  def initialize(*args)
    @id = 1
    @last_feed_refresh = Value.new
    @stash = Stash.new
  end

  def redis
    self.class.redis
  end

  class << self
    attr_accessor :redis

    # stub out stuff from redis-objects
    def hash_key(name); end
    def value(name); end
    def redis_prefix
      name.downcase
    end
  end
end
