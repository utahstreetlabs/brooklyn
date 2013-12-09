require 'active_support/concern'

module Brooklyn
  module RedisConnectable
    extend ActiveSupport::Concern

    included do
      THREAD_LOCAL_REDIS_KEY = "#{self.name}::redis"
    end

    module ClassMethods
      def redis=(connection)
        Thread.current[THREAD_LOCAL_REDIS_KEY] = connection
      end

      def redis
        Thread.current[THREAD_LOCAL_REDIS_KEY]
      end
    end
  end
end
